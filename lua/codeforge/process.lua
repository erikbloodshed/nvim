--[[
Optimized synchronous command execution for compilation using Neovim's libuv.
Runs an external command with arguments, waits for it to finish,
and captures its exit code, standard error, and any script-level errors.

This version returns the error code, stderr, and an optional error_type
with improved resource management, memory efficiency, and error reporting.

Parameters:
  cmd_table: table - A table containing compilation information.
                    It should have the following fields:
                    - compiler: string - The command/executable to run (e.g., 'g++', 'clang++').
                    - arg: table - A list of arguments for the command.
                    - timeout: integer | nil - Optional timeout in milliseconds (default: 30000)
                    - kill_delay: integer | nil - Optional delay before SIGKILL after SIGTERM (default: 2000)

Returns:
  table: A table containing the results:
    - code: integer | nil - The exit code of the command. Nil if terminated by signal.
                          -1 if the function itself failed (e.g., spawn error, invalid input).
    - stderr: string - The standard error output of the command or a script error message.
    - error_type: string | nil - If the script itself failed, this indicates the type of error
                                (e.g., "validation_error", "spawn_error", "timeout_error").
                                Nil if the command executed successfully or failed on its own.
]]
local uv = vim.uv
local fn = vim.fn

-- Configuration constants
local DEFAULT_CONFIG = {
    TIMEOUT_MS = 30000,             -- Default timeout: 30 seconds
    KILL_DELAY_MS = 2000,           -- Default delay before escalating to SIGKILL: 2 seconds
    STDERR_CHUNK_THRESHOLD = 16384, -- Buffer size threshold before concatenating (16KB)
    STDERR_INITIAL_CAPACITY = 16    -- Initial table capacity for typical compilation errors
}

-- OS detection for platform-specific behavior
local is_windows = fn.has('win32') == 1 or fn.has('win64') == 1

-- Signal constants for better readability and platform independence
local SIGNALS = {
    INT = 2,   -- SIGINT
    TERM = 15, -- SIGTERM
    KILL = 9,  -- SIGKILL
    -- Windows will use TerminateProcess regardless of signal, but we define them for consistency
}

-- Pre-allocate common error messages for better memory efficiency and structured errors
local ERROR_MESSAGES = {
    invalid_cmd_table = "Invalid command format: expected a table with 'compiler' and 'arg' fields",
    invalid_compiler = "Invalid command format: 'compiler' must be a non-empty string",
    invalid_args = "Invalid command format: 'arg' must be a table",
    not_executable = "Command not found or not executable: ",
    pipe_creation_failed = "Failed to create necessary pipes for process I/O",
    spawn_failed = "Failed to spawn process: ",
    stderr_read_failed = "Failed to start reading stderr: ",
    stderr_read_error = "Error reading from stderr: ",
    timeout_timer_failed = "Warning: Failed to create timeout timer. Process might hang.",
    process_timed_out = function(timeout) return string.format("\nProcess timed out after %d seconds", timeout / 1000) end,
    event_loop_failed = "Critical Error: libuv event loop failed",
}

-- Optimized error types using numeric codes for better memory efficiency
local ERROR_TYPES = {
    VALIDATION = 1,
    PIPE = 2,
    SPAWN = 3,
    STDERR_READ = 4,
    TIMEOUT = 5,
    LOOP = 6
}

-- Map error type codes to string names for external reporting
local ERROR_TYPE_NAMES = {
    "validation_error",
    "pipe_error",
    "spawn_error",
    "stderr_read_error",
    "timeout_error",
    "loop_error"
}

-- Get error type name from code
local function get_error_type_name(code)
    return code and ERROR_TYPE_NAMES[code]
end

-- Improved resource management with tracked handles and O(1) lookup
local ResourceManager = {
    handles = {}, -- Stores handles for the current ResourceManager instance

    -- Track a handle for later cleanup with O(1) lookup
    track = function(self, handle, handle_type)
        if handle then
            -- Use the handle as key for faster lookups
            self.handles[handle] = handle_type or "generic"
        end
        return handle
    end,

    -- Safe handle closure with improved error handling
    close = function(self, handle, callback)
        if not handle or not self.handles[handle] or uv.is_closing(handle) then
            if callback then pcall(callback) end -- Protect callback execution
            return
        end

        -- Remove from tracked handles and close
        self.handles[handle] = nil
        pcall(uv.close, handle, callback or function() end)
    end,

    -- Clean up all remaining handles for this instance
    cleanup_instance = function(self)
        -- Make a copy since we'll be modifying the original table during iteration
        local handles_to_close = {}
        for handle, _ in pairs(self.handles) do
            table.insert(handles_to_close, handle)
        end

        self.handles = {} -- Clear the instance's handles table

        for _, handle in ipairs(handles_to_close) do
            if handle and not uv.is_closing(handle) then
                pcall(uv.close, handle)
            end
        end
    end
}

-- Global resource manager for VimLeavePre cleanup (safety net)
local GlobalResourceManager = { handles = {} }
setmetatable(GlobalResourceManager, { __index = ResourceManager }) -- Inherit methods

-- Initialize the stderr handling with pre-allocation for better memory efficiency
local function init_stderr_handler()
    local stderr_length = 0
    local stderr_builder = {}

    -- Pre-allocate if using LuaJIT
    if table.new then
        stderr_builder = table.new(DEFAULT_CONFIG.STDERR_INITIAL_CAPACITY, 0)
    end

    -- Return the handler functions and tables
    return {
        -- Add data to the stderr buffer
        add = function(data)
            if data then
                table.insert(stderr_builder, data)
                stderr_length = stderr_length + #data

                -- If we've accumulated enough data, consolidate to prevent excessive fragmentation
                if stderr_length > DEFAULT_CONFIG.STDERR_CHUNK_THRESHOLD then
                    local consolidated = table.concat(stderr_builder)
                    stderr_builder = { consolidated }
                    stderr_length = #consolidated
                end
            end
        end,

        -- Get the final stderr content
        get_content = function()
            return table.concat(stderr_builder)
        end
    }
end

-- Execute a command using libuv
local M = {}

function M.execute(cmd_table)
    -- Extract and normalize configuration
    local timeout_duration = (cmd_table.timeout and tonumber(cmd_table.timeout)) or DEFAULT_CONFIG.TIMEOUT_MS
    local kill_delay = (cmd_table.kill_delay and tonumber(cmd_table.kill_delay)) or DEFAULT_CONFIG.KILL_DELAY_MS

    -- Create a new resource manager instance for this specific execution
    local resources = setmetatable({ handles = {} }, { __index = ResourceManager })

    -- Build result table
    local result = {
        code = -1,       -- Default to -1 for script-level failures
        stderr = "",
        error_type = nil -- Will be set if the script itself errors
    }

    -- Fast path validation with early returns and structured errors
    if type(cmd_table) ~= 'table' then
        result.stderr = ERROR_MESSAGES.invalid_cmd_table
        result.error_type = get_error_type_name(ERROR_TYPES.VALIDATION)
        return result
    end

    local command_path = cmd_table.compiler
    if type(command_path) ~= "string" or command_path == "" then
        result.stderr = ERROR_MESSAGES.invalid_compiler
        result.error_type = get_error_type_name(ERROR_TYPES.VALIDATION)
        return result
    end

    local command_args = cmd_table.arg
    if type(command_args) ~= 'table' then
        result.stderr = ERROR_MESSAGES.invalid_args
        result.error_type = get_error_type_name(ERROR_TYPES.VALIDATION)
        return result
    end

    -- Resolve command path to handle relative paths consistently
    local resolved_path = fn.exepath(command_path)
    if resolved_path == "" then
        result.stderr = ERROR_MESSAGES.not_executable .. command_path
        result.error_type = get_error_type_name(ERROR_TYPES.VALIDATION)
        return result
    end
    command_path = resolved_path -- Use the fully resolved path

    -- Use a single status table to track everything
    local status = {
        pending_closures = 2, -- stdin + stderr pipes initially
        process_exited = false,
        stderr_handler = init_stderr_handler(),
    }

    local completed = false -- Flag to prevent multiple completions

    -- Completion function to finalize results and clean up
    local function complete()
        if completed then return end
        completed = true

        -- Build final stderr output efficiently if not already set by a script error
        if result.stderr == "" then
            result.stderr = status.stderr_handler.get_content()
        end

        -- Clean up resources specific to this execution
        resources:cleanup_instance()

        -- Stop the event loop if it's still running.
        -- This is crucial for the synchronous-like behavior of M.execute().
        if uv.loop_alive() then
            uv.stop()
        end
    end

    -- Create necessary pipes with resource tracking
    local stdin_pipe = resources:track(uv.new_pipe(false), "stdin_pipe")
    local stderr_pipe = resources:track(uv.new_pipe(false), "stderr_pipe")

    if not stdin_pipe or not stderr_pipe then
        result.stderr = ERROR_MESSAGES.pipe_creation_failed
        result.error_type = get_error_type_name(ERROR_TYPES.PIPE)
        complete() -- Ensure cleanup and loop stop
        return result
    end

    -- Simplified pipe closure handler
    local function on_pipe_close()
        status.pending_closures = status.pending_closures - 1
        if status.pending_closures <= 0 and status.process_exited then
            complete()
        end
    end

    -- Process exit handler
    local function on_exit(code, signal) -- Libuv provides code and signal
        -- If code is nil and signal is not 0, process was terminated by a signal.
        -- We primarily care about the exit code for compilation success/failure.
        -- If terminated by signal, 'code' will be nil. We can choose to report signal
        -- or stick to the original behavior of nil code. For simplicity, stick to 'code'.
        result.code = code
        if signal ~= 0 and code == nil then
            -- Optionally, indicate termination by signal in stderr or a new field
            status.stderr_handler.add(string.format("\nProcess terminated by signal: %d", signal))
        end

        status.process_exited = true

        -- Ensure pipes are closed. These might already be closing or closed.
        resources:close(stderr_pipe, on_pipe_close)
        resources:close(stdin_pipe, on_pipe_close) -- stdin is closed earlier, but safe to call again

        if status.pending_closures <= 0 then
            complete()
        end
    end

    -- Optimized stderr reader
    local function on_stderr_read(err, data)
        if err then
            status.stderr_handler.add(ERROR_MESSAGES.stderr_read_error .. tostring(err))
            -- Don't set result.error_type here as it's an I/O error with the child process,
            -- not necessarily a script setup error. The command's exit code will be more relevant.
            resources:close(stderr_pipe, on_pipe_close)
            return
        end

        if data then
            status.stderr_handler.add(data)
        else -- EOF
            resources:close(stderr_pipe, on_pipe_close)
        end
    end

    -- Spawn the process
    local spawn_options = {
        args = command_args,
        stdio = { stdin_pipe, nil, stderr_pipe } -- No stdout pipe needed
    }

    local process_handle, spawn_pid_or_err = uv.spawn(command_path, spawn_options, on_exit)

    if not process_handle then
        result.stderr = ERROR_MESSAGES.spawn_failed .. tostring(spawn_pid_or_err)
        result.error_type = get_error_type_name(ERROR_TYPES.SPAWN)
        -- Clean up pipes that were created before spawn failed
        resources:close(stderr_pipe, on_pipe_close)
        resources:close(stdin_pipe, on_pipe_close)
        complete()
        return result
    end
    resources:track(process_handle, "process") -- Track successful process handle

    -- Start reading stderr
    local read_start_ok, read_err = pcall(uv.read_start, stderr_pipe, on_stderr_read)
    if not read_start_ok then
        result.stderr = ERROR_MESSAGES.stderr_read_failed .. tostring(read_err)
        result.error_type = get_error_type_name(ERROR_TYPES.STDERR_READ) -- This is a script setup failure
        -- Process is running, but we can't read its stderr. Attempt to kill and cleanup.
        if not is_windows then
            pcall(uv.process_kill, process_handle, SIGNALS.TERM) -- SIGTERM
        else
            pcall(uv.process_kill, process_handle, 15)           -- Windows will use TerminateProcess
        end
        resources:close(stderr_pipe, on_pipe_close)
        complete()
        return result
    end

    -- Close stdin immediately as we don't write to it
    resources:close(stdin_pipe, on_pipe_close)

    -- Set a timeout
    local timeout_timer = resources:track(uv.new_timer(), "timeout_timer")

    if timeout_timer then
        uv.timer_start(timeout_timer, timeout_duration, 0, function()
            if completed then return end -- Already completed (e.g. process finished quickly)

            -- Process timed out
            result.error_type = get_error_type_name(ERROR_TYPES.TIMEOUT) -- Mark as a timeout error from the script's perspective
            status.stderr_handler.add(ERROR_MESSAGES.process_timed_out(timeout_duration))
            result.code = -1                                             -- Indicate script-level failure due to timeout

            -- Graduated process termination strategy
            if process_handle and not uv.is_closing(process_handle) then
                -- First try SIGINT for graceful termination if not Windows
                if not is_windows then
                    pcall(uv.process_kill, process_handle, SIGNALS.INT) -- SIGINT

                    -- Then SIGTERM after short delay
                    local sigterm_timer = resources:track(uv.new_timer(), "sigterm_timer")
                    if sigterm_timer then
                        uv.timer_start(sigterm_timer, 1000, 0, function()
                            if process_handle and not uv.is_closing(process_handle) then
                                pcall(uv.process_kill, process_handle, SIGNALS.TERM) -- SIGTERM
                            end
                            resources:close(sigterm_timer)
                        end)
                    end
                else
                    -- Windows - just use process_kill (will be TerminateProcess)
                    pcall(uv.process_kill, process_handle, 15)
                end

                -- Finally SIGKILL as last resort
                local kill_timer = resources:track(uv.new_timer(), "kill_timer_fallback")
                if kill_timer then
                    uv.timer_start(kill_timer, kill_delay, 0, function()
                        if process_handle and not uv.is_closing(process_handle) then
                            if not is_windows then
                                pcall(uv.process_kill, process_handle, SIGNALS.KILL) -- SIGKILL
                            else
                                pcall(uv.process_kill, process_handle, 9)            -- Windows will use TerminateProcess
                            end
                        end
                        resources:close(kill_timer) -- Close the kill_timer itself
                    end)
                end
            end
            complete()                     -- This will also stop the loop
            resources:close(timeout_timer) -- Ensure timeout_timer itself is closed
        end)
    else
        -- If timer creation fails, we can't enforce timeout. Log it.
        status.stderr_handler.add(ERROR_MESSAGES.timeout_timer_failed)
        -- No result.error_type here, as it's a warning; the command might still complete.
    end

    -- Run the libuv event loop with explicit mode for better performance.
    -- This call will block until uv.stop() is called (in complete()) or the loop has no active handles.
    -- This is what gives M.execute() its synchronous-like behavior from the caller's perspective.
    local success, loop_err = pcall(uv.run, "default") -- Specify explicit run mode
    if not success and not completed then
        -- This is a critical failure of the event loop itself.
        result.stderr = ERROR_MESSAGES.event_loop_failed .. (loop_err and (": " .. tostring(loop_err)) or "")
        result.error_type = get_error_type_name(ERROR_TYPES.LOOP)
        result.code = -1
        complete() -- Attempt to cleanup and ensure everything stops
    end

    -- Final safety net: if complete() was not called for some reason (e.g. error in uv.run before callbacks)
    if not completed then
        complete()
    end

    return result
end

-- Cleanup on module unload to prevent resource leaks from unexpected exits or errors
-- This uses the GlobalResourceManager as a safety net for any handles that might
-- somehow be orphaned if an execution context didn't clean up properly.
vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        -- This is a global cleanup for any handles that might have been
        -- tracked by GlobalResourceManager if used, or as a conceptual placeholder.
        -- In the current design, each `M.execute` has its own `resources` manager.
        -- This global cleanup is more of a failsafe if the design were different
        -- or if handles were somehow leaked to a global scope.
        GlobalResourceManager:cleanup_instance() -- If it were used to track handles globally
    end,
    desc = "Ensure libuv handles from process module are cleaned up"
})

return M
