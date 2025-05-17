-- BufferSwitcher: utilities module
local M = {}

-- Configurable delay for debouncing updates
local debounce_delay = 100 -- milliseconds
local debounce_timer = nil
local hide_timer = nil

-- Function to check if current buffer is a special buffer
function M.is_special_buffer(config, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    -- Check buffer type
    local buf_type = vim.bo[bufnr].buftype
    local buf_filetype = vim.bo[bufnr].filetype
    local buf_name = vim.fn.bufname(bufnr)

    -- Check buftypes
    for _, btype in ipairs(config.special_buftypes) do
        if buf_type == btype then
            return true
        end
    end

    -- Check filetypes
    for _, ftype in ipairs(config.special_filetypes) do
        if buf_filetype == ftype then
            return true
        end
    end

    -- Check buffer name patterns
    for _, pattern in ipairs(config.special_bufname_patterns) do
        if buf_name:match(pattern) then
            return true
        end
    end

    -- Check window options for known special windows
    if vim.fn.win_gettype() ~= "" then -- Not a normal window
        return true
    end

    return false
end

-- Enhanced function to check if a buffer should be included in our buffer list
function M.should_include_buffer(config, bufnr)
    -- Basic validity check
    if not vim.api.nvim_buf_is_valid(bufnr) or vim.fn.buflisted(bufnr) ~= 1 then
        return false
    end

    local buf_name = vim.fn.bufname(bufnr)
    local buf_type = vim.bo[bufnr].buftype

    -- Filter out special buffer types
    if vim.tbl_contains(config.exclude_buftypes, buf_type) then
        return false
    end

    -- Filter out specific filetypes
    if vim.tbl_contains(config.exclude_filetypes, vim.bo[bufnr].filetype) then
        return false
    end

    -- Filter out unnamed buffers with no changes
    if buf_name == "" and vim.fn.getbufvar(bufnr, '&modified') == 0 then
        -- Only include unnamed buffers if they have content
        local line_count = vim.api.nvim_buf_line_count(bufnr)
        local has_content = false

        -- Check if buffer has any non-empty lines
        if line_count > 1 then
            has_content = true
        elseif line_count == 1 then
            local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
            has_content = first_line and #first_line > 0
        end

        return has_content
    end

    return true
end

-- Safely clean up timer resources
function M.cleanup_timer(timer)
    if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
        return true
    end
    return false
end

-- Set the debounce delay for UI updates
function M.set_debounce_delay(delay_ms)
    if type(delay_ms) == "number" and delay_ms > 0 then
        debounce_delay = delay_ms
        return true
    else
        vim.notify("Invalid debounce delay: must be a positive number", vim.log.levels.WARN)
        return false
    end
end

-- Safe command execution with error handling
function M.safe_command(cmd)
    local status, _ = pcall(vim.api.nvim_command, cmd)
    return status
end

-- Create a new debounced function
function M.debounce(fn)
    if M.cleanup_timer(debounce_timer) then
        debounce_timer = nil
    end

    debounce_timer = vim.uv.new_timer()

    if debounce_timer then
        local success, err = pcall(function()
            debounce_timer:start(debounce_delay, 0, vim.schedule_wrap(function()
                local status, err_msg = pcall(fn)
                if not status then
                    vim.notify("Error in debounced function: " .. tostring(err_msg), vim.log.levels.ERROR)
                end

                if M.cleanup_timer(debounce_timer) then
                    debounce_timer = nil
                end
            end))
        end)

        if not success then
            vim.notify("Failed to start debounce timer: " .. tostring(err), vim.log.levels.ERROR)
            if M.cleanup_timer(debounce_timer) then
                debounce_timer = nil
            end
        end
    else
        -- Fallback in case timer creation fails
        vim.notify("Failed to create debounce timer", vim.log.levels.WARN)
        vim.schedule(fn)
    end
end

-- Get and properly manage hide timer
function M.get_hide_timer()
    return hide_timer
end

function M.set_hide_timer(timer)
    hide_timer = timer
end

return M
