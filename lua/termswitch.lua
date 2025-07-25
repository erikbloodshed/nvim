-- luacheck: globals vim

local M = {}

---@class TermSwitchConfig
---@field width number
---@field height number
---@field border 'none' | 'single' | 'double' | 'rounded' | 'solid' | 'shadow'
---@field default_shell string | nil

-- Default configuration
---@type TermSwitchConfig
local config = {
    width = 0.8,         -- 80% of editor width
    height = 0.8,        -- 80% of editor height
    border = 'rounded',  -- Border style: 'none', 'single', 'double', 'rounded', 'solid', 'shadow'
    default_shell = nil, -- e.g., '/bin/bash' or 'pwsh.exe'
}

-- Store terminal buffer and window IDs
local state = {
    term_buf = nil,
    term_win = nil,
}

--- Creates the configuration table for the floating window.
--- @private
--- @return table float_config The configuration table for nvim_open_win.
local function get_float_config()
    local ui = vim.api.nvim_list_uis()[1]
    local width = math.floor(ui.width * config.width)
    local height = math.floor(ui.height * config.height)
    local col = math.floor((ui.width - width) / 2)
    local row = math.floor((ui.height - height) / 2)

    return {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = config.border,
        title = ' Terminal ',
        title_pos = 'center',
    }
end

--- Ensures the terminal buffer exists and is valid.
--- Creates a new one if it doesn't exist or is invalid.
--- @private
local function ensure_terminal_buffer()
    if state.term_buf == nil or not vim.api.nvim_buf_is_valid(state.term_buf) then
        state.term_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value('buflisted', false, { buf = state.term_buf })
        vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = state.term_buf })
        -- Set filetype for syntax highlighting if desired, though 'terminal' is usually enough
        vim.api.nvim_set_option_value('filetype', 'terminal', { buf = state.term_buf })
    end
end

--- Sets common options for the terminal window.
--- @private
--- @param win_id number The ID of the terminal window.
local function setup_terminal_window_options(win_id)
    vim.api.nvim_set_option_value('number', false, { win = win_id })
    vim.api.nvim_set_option_value('relativenumber', false, { win = win_id })
    vim.api.nvim_set_option_value('signcolumn', 'no', { win = win_id })
    vim.api.nvim_set_option_value('wrap', false, { win = win_id })
    vim.api.nvim_set_option_value('winhighlight', 'Normal:Normal,FloatBorder:FloatBorder', { win = win_id })
end

--- Starts the terminal process in the buffer if it's not already running.
--- @private
local function start_terminal_process()
    -- Check if the buffer is already a terminal
    if vim.api.nvim_get_option_value('buftype', { buf = state.term_buf }) ~= 'terminal' then
        vim.api.nvim_set_current_buf(state.term_buf) -- Ensure we are on the correct buffer
        local term_cmd = 'terminal'
        if config.default_shell then
            term_cmd = string.format("terminal %s", vim.fn.shellescape(config.default_shell))
        end
        vim.cmd(term_cmd)
        -- After vim.cmd.terminal(), the current buffer becomes the terminal buffer.
        -- We need to update our stored buffer ID to this new one, as it might be different.
        state.term_buf = vim.api.nvim_get_current_buf()
    end
end

--- Opens and displays the floating terminal window.
--- Creates the window if it doesn't exist, or just focuses it if it does.
--- @private
local function open_terminal()
    ensure_terminal_buffer()

    if state.term_win == nil or not vim.api.nvim_win_is_valid(state.term_win) then
        local float_config = get_float_config()
        state.term_win = vim.api.nvim_open_win(state.term_buf, true, float_config)
        setup_terminal_window_options(state.term_win)
        start_terminal_process()

        -- Set up autocmd to clean up when window is closed
        -- Using a named autocmd group for easier management and removal
        vim.api.nvim_create_autocmd('WinClosed', {
            group = vim.api.nvim_create_augroup('TermSwitchWinClosed', { clear = true }),
            pattern = tostring(state.term_win),
            callback = function()
                state.term_win = nil
                -- Optionally, if you want to also clear the buffer when the window is closed,
                -- but typically you'd keep the buffer unless explicitly quit.
                -- if vim.api.nvim_buf_is_valid(state.term_buf) then
                --     vim.api.nvim_buf_delete(state.term_buf, { force = true })
                --     state.term_buf = nil
                -- end
            end,
            once = true,
        })
    else
        -- If window exists, just focus it
        vim.api.nvim_set_current_win(state.term_win)
    end

    -- Enter terminal mode
    vim.api.nvim_command('startinsert')
end

--- Hides the floating terminal window.
--- @private
local function hide_terminal()
    if state.term_win ~= nil and vim.api.nvim_win_is_valid(state.term_win) then
        vim.api.nvim_win_close(state.term_win, false)
        state.term_win = nil
        -- Clear the autocmd since the window is now closed
        vim.api.nvim_clear_autocmds({ group = 'TermSwitchWinClosed', pattern = tostring(state.term_win) })
    end
end

--- Toggles the visibility of the floating terminal.
function M.toggle_terminal()
    if state.term_win ~= nil and vim.api.nvim_win_is_valid(state.term_win) then
        hide_terminal()
    else
        open_terminal()
    end
end

--- Sets up the plugin with user configuration.
--- @param user_config TermSwitchConfig | nil Optional user configuration table.
function M.setup(user_config)
    -- Validate and merge configuration
    if user_config then
        config = vim.tbl_extend('force', config, user_config)
        -- Basic validation for width/height/border
        if config.width <= 0 or config.width > 1 then
            vim.notify("TermSwitch: 'width' must be between 0 and 1. Using default.", vim.log.levels.WARN)
            config.width = 0.8
        end
        if config.height <= 0 or config.height > 1 then
            vim.notify("TermSwitch: 'height' must be between 0 and 1. Using default.", vim.log.levels.WARN)
            config.height = 0.8
        end
        local valid_borders = { 'none', 'single', 'double', 'rounded', 'solid', 'shadow' }
        if not vim.tbl_contains(valid_borders, config.border) then
            vim.notify(string.format("TermSwitch: Invalid 'border' style '%s'. Using 'rounded'.", config.border),
                vim.log.levels.WARN)
            config.border = 'rounded'
        end
    end

    -- Create user command
    -- Using `desc` for better help output (`:h :command-arguments`)
    vim.api.nvim_create_user_command('ToggleTerm', M.toggle_terminal, { desc = 'Toggle floating terminal window' })

    -- Default keymappings
    -- It's generally better to let users define their own mappings,
    -- but for a simple plugin, defaults are fine.
    -- Ensure these don't override existing maps unless intended.
    -- Also, consider using `vim.keymap.set` for new Nvim versions for better ergonomics.
    vim.api.nvim_set_keymap('n', '<leader>tt', ':ToggleTerm<CR>',
        { noremap = true, silent = true, desc = 'Toggle Terminal (Normal mode)' })
    vim.api.nvim_set_keymap('t', '<leader>tt', '<C-\\><C-n>:ToggleTerm<CR>',
        { noremap = true, silent = true, desc = 'Toggle Terminal (Terminal mode)' })

    -- Additional escape keymapping for floating terminal
    -- This is crucial for exiting terminal mode in a floating window easily.
    vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', { noremap = true, silent = true, desc = 'Exit terminal mode' })
end

return M
