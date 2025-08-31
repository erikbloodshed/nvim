--[[
Simplified synchronous command execution for running compilers/assemblers in Neovim using libuv.
Executes a command, waits for completion, and captures stderr for error reporting.

Parameters:
  cmd_table: table - Compilation command details with fields:
                    - compiler: string - The command to run (e.g., 'g++', 'nasm').
                    - arg: table - List of command arguments.
                    - timeout: integer | nil - Timeout in milliseconds (default: 30000).

Returns:
  table: Results containing:
    - code: integer | nil - Exit code of the command. Nil if terminated by signal.
                          -1 if the script failed (e.g., invalid input, spawn error).
    - stderr: string - Standard error output or script error message.
    - error_type: string | nil - Type of script error (e.g., 'validation', 'spawn', 'timeout').
                                Nil if the command executed or failed normally.

Notes:
  - Designed for compilers/assemblers; only captures stderr.
  - On timeout, the process is terminated with SIGTERM (or TerminateProcess on Windows).
  - If terminated by a signal, 'code' is nil, and stderr may note the signal.
]]
local uv, fn = vim.uv, vim.fn

-- Configuration constants
local DEFAULT_CONFIG = {
  TIMEOUT_MS = 30000,             -- Default timeout: 30 seconds
  STDERR_CHUNK_THRESHOLD = 16384, -- Buffer size threshold for stderr (16KB)
  STDERR_INITIAL_CAPACITY = 16    -- Initial table capacity for stderr
}

-- Signal constant
local SIGTERM = 15

-- Error messages
local ERROR_MESSAGES = {
  invalid_cmd_table = 'Invalid command: expected table with "compiler" and "arg" fields',
  invalid_compiler = 'Invalid command: "compiler" must be a non-empty string',
  invalid_args = 'Invalid command: "arg" must be a table',
  invalid_timeout = 'Invalid timeout: must be a positive integer',
  not_executable = 'Command not found or not executable: ',
  pipe_creation_failed = 'Failed to create pipes for process I/O',
  spawn_failed = 'Failed to spawn process: ',
  stderr_read_failed = 'Failed to start reading stderr: ',
  stderr_read_error = 'Error reading stderr: ',
  timeout_timer_failed = 'Failed to create timeout timer',
  process_timed_out = function(timeout) return string.format('\nProcess timed out after %d seconds', timeout / 1000) end,
  event_loop_failed = 'Critical error: libuv event loop failed',
}

-- Error types
local ERROR_TYPES = {
  VALIDATION = 'validation',
  PIPE = 'pipe',
  SPAWN = 'spawn',
  STDERR_READ = 'stderr_read',
  TIMEOUT = 'timeout',
  LOOP = 'loop'
}

-- ResourceManager for handle cleanup
local ResourceManager = {
  handles = {},
  track = function(self, handle, handle_type)
    if handle then
      self.handles[handle] = handle_type or 'generic'
    end
    return handle
  end,
  close = function(self, handle, callback)
    if not handle or not self.handles[handle] or uv.is_closing(handle) then
      if callback then pcall(callback) end
      return
    end
    self.handles[handle] = nil
    pcall(uv.close, handle, callback or function() end)
  end,
  cleanup_instance = function(self)
    for handle, _ in pairs(self.handles) do
      if handle and not uv.is_closing(handle) then
        pcall(uv.close, handle)
      end
    end
    self.handles = {} -- Reset the table
  end,
}

-- Initialize stderr handler
local function init_stderr_handler()
  local length = 0
  local builder = table.new and table.new(DEFAULT_CONFIG.STDERR_INITIAL_CAPACITY, 0) or {}
  return {
    add = function(data)
      if data then
        table.insert(builder, data)
        length = length + #data
        if length > DEFAULT_CONFIG.STDERR_CHUNK_THRESHOLD then
          local consolidated = table.concat(builder)
          builder = { consolidated }
          length = #consolidated
        end
      end
    end,
    get_content = function()
      return table.concat(builder)
    end
  }
end

-- Execute a command
local M = {}

M.execute = function(cmd_table)
  -- Validate and normalize configuration
  local timeout_duration = (cmd_table.timeout and tonumber(cmd_table.timeout)) or DEFAULT_CONFIG.TIMEOUT_MS
  local resources = setmetatable({ handles = {} }, { __index = ResourceManager })
  local result = { code = -1, stderr = '', error_type = nil }

  -- Input validation
  if type(cmd_table) ~= 'table' then
    result.stderr = ERROR_MESSAGES.invalid_cmd_table
    result.error_type = ERROR_TYPES.VALIDATION
    return result
  end

  local command_path = cmd_table.compiler
  if type(command_path) ~= 'string' or command_path == '' then
    result.stderr = ERROR_MESSAGES.invalid_compiler
    result.error_type = ERROR_TYPES.VALIDATION
    return result
  end

  local command_args = cmd_table.arg
  if type(command_args) ~= 'table' then
    result.stderr = ERROR_MESSAGES.invalid_args
    result.error_type = ERROR_TYPES.VALIDATION
    return result
  end

  if timeout_duration <= 0 then
    result.stderr = ERROR_MESSAGES.invalid_timeout
    result.error_type = ERROR_TYPES.VALIDATION
    return result
  end

  -- Resolve command path
  local resolved_path = fn.exepath(command_path)
  if resolved_path == '' then
    result.stderr = ERROR_MESSAGES.not_executable .. command_path
    result.error_type = ERROR_TYPES.VALIDATION
    return result
  end
  command_path = resolved_path

  -- Initialize status
  local status = {
    pending_closures = 2, -- stdin, stderr
    process_exited = false,
    stderr_handler = init_stderr_handler(),
  }
  local completed = false
  local timeout_timer -- Forward-declare for use in on_exit

  local function complete()
    if completed then return end
    completed = true
    result.stderr = status.stderr_handler.get_content()
    resources:cleanup_instance()
    if uv.loop_alive() then
      uv.stop()
    end
  end

  -- Create pipes
  local stdin_pipe = resources:track(uv.new_pipe(false), 'stdin_pipe')
  local stderr_pipe = resources:track(uv.new_pipe(false), 'stderr_pipe')
  if not stdin_pipe or not stderr_pipe then
    result.stderr = ERROR_MESSAGES.pipe_creation_failed
    result.error_type = ERROR_TYPES.PIPE
    complete()
    return result
  end

  local function on_pipe_close()
    status.pending_closures = status.pending_closures - 1
    if status.pending_closures <= 0 and status.process_exited then
      complete()
    end
  end

  local function on_exit(code, signal)
    if timeout_timer and not uv.is_closing(timeout_timer) then
      uv.timer_stop(timeout_timer)
      resources:close(timeout_timer)
    end

    result.code = code
    if signal ~= 0 and code == nil then
      status.stderr_handler.add(string.format('\nProcess terminated by signal: %d', signal))
    end
    status.process_exited = true
    resources:close(stderr_pipe, on_pipe_close)
    resources:close(stdin_pipe, on_pipe_close)
    if status.pending_closures <= 0 then
      complete()
    end
  end

  local function on_stderr_read(err, data)
    if err then
      status.stderr_handler.add(ERROR_MESSAGES.stderr_read_error .. tostring(err))
      resources:close(stderr_pipe, on_pipe_close)
      return
    end
    if data then
      status.stderr_handler.add(data)
    else
      resources:close(stderr_pipe, on_pipe_close)
    end
  end

  -- Spawn the process
  local spawn_options = { args = command_args, stdio = { stdin_pipe, nil, stderr_pipe } }
  local process_handle, spawn_pid_or_err = uv.spawn(command_path, spawn_options, on_exit)
  if not process_handle then
    result.stderr = ERROR_MESSAGES.spawn_failed .. tostring(spawn_pid_or_err)
    result.error_type = ERROR_TYPES.SPAWN
    complete()
    return result
  end
  resources:track(process_handle, 'process')

  -- Start reading stderr
  local read_start_ok, read_err = pcall(uv.read_start, stderr_pipe, on_stderr_read)
  if not read_start_ok then
    result.stderr = ERROR_MESSAGES.stderr_read_failed .. tostring(read_err)
    result.error_type = ERROR_TYPES.STDERR_READ
    pcall(uv.process_kill, process_handle, SIGTERM)
    complete()
    return result
  end

  resources:close(stdin_pipe, on_pipe_close)

  -- Set timeout
  timeout_timer = resources:track(uv.new_timer(), 'timeout_timer')
  if not timeout_timer then
    result.stderr = ERROR_MESSAGES.timeout_timer_failed
    result.error_type = ERROR_TYPES.TIMEOUT
    pcall(uv.process_kill, process_handle, SIGTERM)
    complete()
    return result
  end

  uv.timer_start(timeout_timer, timeout_duration, 0, function()
    if completed then return end
    result.error_type = ERROR_TYPES.TIMEOUT
    status.stderr_handler.add(ERROR_MESSAGES.process_timed_out(timeout_duration))
    result.code = -1
    if process_handle and not uv.is_closing(process_handle) then
      pcall(uv.process_kill, process_handle, SIGTERM)
    end
    complete()
    resources:close(timeout_timer)
  end)

  local success, loop_err = pcall(uv.run, 'default')
  if not success and not completed then
    result.stderr = ERROR_MESSAGES.event_loop_failed .. (loop_err and (': ' .. tostring(loop_err)) or '')
    result.error_type = ERROR_TYPES.LOOP
    result.code = -1
    complete()
  end

  if not completed then
    complete()
  end

  return result
end

return M
