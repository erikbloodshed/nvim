-- BufferSwitcher: core buffer management module
local M = {}

local utils = require('bufferswitch.utils')
local tabline = require('bufferswitch.tabline')

-- Table to store the order of listed buffers
local buffer_order = {}
local config = {}

-- Function to add a buffer to the order if it's not already present
local function add_buffer_to_order(bufnr)
    if utils.should_include_buffer(config, bufnr) then
        local found = false
        for _, existing_bufnr in ipairs(buffer_order) do
            if existing_bufnr == bufnr then
                found = true
                break
            end
        end
        if not found then
            table.insert(buffer_order, bufnr)
        end
    end
end

-- Function to remove a buffer from the order
local function remove_buffer_from_order(bufnr)
    for i, existing_bufnr in ipairs(buffer_order) do
        if existing_bufnr == bufnr then
            table.remove(buffer_order, i)
            break
        end
    end
end

-- Function to clean buffer_order by removing any buffers that should no longer be included
local function sanitize_buffer_order()
    local i = 1
    while i <= #buffer_order do
        local bufnr = buffer_order[i]
        if not utils.should_include_buffer(config, bufnr) then
            table.remove(buffer_order, i)
        else
            i = i + 1
        end
    end
end

-- This function can be called periodically or after quickfix operations
function M.refresh_buffer_list()
    -- Clean up the existing buffer order
    sanitize_buffer_order()

    -- Check if we need to add any valid buffers that might be missing
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        add_buffer_to_order(bufnr)
    end

    -- Update the display if needed
    if vim.o.showtabline == 2 then
        tabline.debounced_update_tabline(buffer_order)
    end
end

-- Navigate buffers safely - next
function M.next_buffer()
    -- Don't navigate if we're in a special buffer
    if config.disable_in_special and utils.is_special_buffer(config) then
        -- Optionally pass through to regular next buffer command
        if config.passthrough_keys_in_special then
            local key = vim.api.nvim_replace_termcodes(config.orig_next_key or "<C-n>", true, true, true)
            vim.api.nvim_feedkeys(key, 'n', false)
        end
        return
    end

    local current_buf = vim.api.nvim_get_current_buf()

    -- If we have multiple buffers
    if #buffer_order > 1 then
        -- Try standard command first
        if not utils.safe_command("silent! bnext") then
            -- If that fails, try to find next buffer manually
            local found_current = false
            local next_buf = nil

            for _, bufnr in ipairs(buffer_order) do
                if found_current then
                    next_buf = bufnr
                    break
                end
                if bufnr == current_buf then
                    found_current = true
                end
            end

            -- Wrap around if needed
            if not next_buf and #buffer_order > 0 then
                next_buf = buffer_order[1]
            end

            -- Switch to the buffer if found
            if next_buf and next_buf ~= current_buf then
                vim.api.nvim_set_current_buf(next_buf)
            end
        end
    else
        vim.notify("No other buffers to navigate to", vim.log.levels.INFO)
    end

    -- Always update tabline
    tabline.manage_tabline(config, buffer_order)
end

-- Navigate buffers safely - previous
function M.prev_buffer()
    -- Don't navigate if we're in a special buffer
    if config.disable_in_special and utils.is_special_buffer(config) then
        -- Optionally pass through to regular prev buffer command
        if config.passthrough_keys_in_special then
            local key = vim.api.nvim_replace_termcodes(config.orig_prev_key or "<C-p>", true, true, true)
            vim.api.nvim_feedkeys(key, 'n', false)
        end
        return
    end

    local current_buf = vim.api.nvim_get_current_buf()

    -- If we have multiple buffers
    if #buffer_order > 1 then
        -- Try standard command first
        if not utils.safe_command("silent! bprevious") then
            -- If that fails, try to find previous buffer manually
            local prev_buf = nil
            local found_index = nil

            -- Find current buffer index
            for i, bufnr in ipairs(buffer_order) do
                if bufnr == current_buf then
                    found_index = i
                    break
                end
            end

            -- Get previous with wrap-around
            if found_index then
                if found_index > 1 then
                    prev_buf = buffer_order[found_index - 1]
                else
                    prev_buf = buffer_order[#buffer_order]
                end
            end

            -- Switch to the buffer if found
            if prev_buf and prev_buf ~= current_buf then
                vim.api.nvim_set_current_buf(prev_buf)
            end
        end
    else
        vim.notify("No other buffers to navigate to", vim.log.levels.INFO)
    end

    -- Always update tabline
    tabline.manage_tabline(config, buffer_order)
end

-- Debug function to print buffer list
function M.debug_buffers()
    print("Current buffer order:")
    for i, bufnr in ipairs(buffer_order) do
        local name = vim.fn.bufname(bufnr)
        if name == "" then name = "[No Name]" end
        print(string.format("%d: %s (bufnr=%d)", i, name, bufnr))
    end
end

-- Initialize the plugin with config and autocommands
function M.initialize(user_config)
    config = user_config

    if config.show_tabline then
        vim.o.showtabline = 0
    end

    local ag = vim.api.nvim_create_augroup('BufferSwitcher', { clear = true })

    -- Initialize buffer_order with current valid buffers
    buffer_order = {}
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        add_buffer_to_order(bufnr)
    end

    -- Update buffer order and tabline on relevant events
    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        group = ag,
        callback = function()
            local current_buf = vim.api.nvim_get_current_buf()

            -- Check if we should show tabline based on buffer type
            if config.hide_in_special and utils.is_special_buffer(config, current_buf) then
                if vim.o.showtabline == 2 then
                    vim.o.showtabline = 0
                end
                return
            end

            add_buffer_to_order(current_buf)
            -- Move the current buffer to the end of the order
            -- local found_index = nil
            -- for i, bufnr in ipairs(buffer_order) do
            --     if bufnr == current_buf then
            --         found_index = i
            --         break
            --     end
            -- end
            -- if found_index and found_index < #buffer_order then
            --     table.remove(buffer_order, found_index)
            --     table.insert(buffer_order, current_buf)
            -- end
            if config.show_tabline and vim.o.showtabline == 2 then
                tabline.debounced_update_tabline(buffer_order)
            end
        end,
    })

    vim.api.nvim_create_autocmd({ 'BufAdd' }, {
        group = ag,
        callback = function(ev)
            add_buffer_to_order(ev.buf)
            if config.show_tabline and vim.o.showtabline == 2 then
                tabline.debounced_update_tabline(buffer_order)
            end
        end,
    })

    vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
        group = ag,
        callback = function(ev)
            remove_buffer_from_order(ev.buf)
            if config.show_tabline and vim.o.showtabline == 2 then
                tabline.debounced_update_tabline(buffer_order)
            end
        end,
    })

    -- Add specific handlers for quickfix window events
    vim.api.nvim_create_autocmd({ 'QuickFixCmdPost', 'QuickFixCmdPre' }, {
        group = ag,
        callback = function()
            -- Schedule the refresh to run after quickfix operations are complete
            vim.schedule(M.refresh_buffer_list)
        end,
    })

    -- Also clean up when windows are closed (which may include quickfix)
    vim.api.nvim_create_autocmd({ 'WinClosed' }, {
        group = ag,
        callback = function()
            vim.schedule(M.refresh_buffer_list)
        end,
    })

    -- Periodically sanitize the buffer list
    if config.periodic_cleanup then
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            group = ag,
            callback = function()
                sanitize_buffer_order()
            end,
        })
    end

    -- Make buffer_order accessible externally for other modules
    M.get_buffer_order = function()
        return buffer_order
    end
end

return M
