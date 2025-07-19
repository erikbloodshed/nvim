local M = {}

-- Store terminal buffer and window IDs
local term_buf = nil
local term_win = nil

-- Default configuration
local config = {
    size = 0.3,        -- 30% of window height
    position = 'bottom', -- Terminal position
}

-- Create or show terminal
local function open_terminal()
    -- Get current window dimensions
    local win_height = vim.api.nvim_win_get_height(0)
    local height = math.floor(win_height * config.size)

    -- Create new terminal buffer if none exists
    if term_buf == nil or not vim.api.nvim_buf_is_valid(term_buf) then
        term_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(term_buf, 'buflisted', false)
    end

    -- Create window if it doesn't exist
    if term_win == nil or not vim.api.nvim_win_is_valid(term_win) then
        -- Store current window to return focus
        local current_win = vim.api.nvim_get_current_win()

        -- Create new split
        vim.api.nvim_command('belowright ' .. height .. 'split')
        term_win = vim.api.nvim_get_current_win()

        -- Set terminal buffer in new window
        vim.api.nvim_win_set_buf(term_win, term_buf)

        -- Start terminal in the new buffer if it's not already a terminal
        if vim.api.nvim_buf_get_option(term_buf, 'buftype') ~= 'terminal' then
            vim.api.nvim_command('terminal')
            term_buf = vim.api.nvim_get_current_buf()
        end

        -- Set window options
        vim.api.nvim_win_set_option(term_win, 'number', false)
        vim.api.nvim_win_set_option(term_win, 'relativenumber', false)
        vim.api.nvim_win_set_option(term_win, 'signcolumn', 'no')

        -- Return focus to original window
        vim.api.nvim_set_current_win(current_win)
    end

    -- Enter terminal mode
    vim.api.nvim_set_current_win(term_win)
    vim.api.nvim_command('startinsert')
end

-- Hide terminal
local function hide_terminal()
    if term_win ~= nil and vim.api.nvim_win_is_valid(term_win) then
        vim.api.nvim_win_hide(term_win)
        term_win = nil
    end
end

-- Toggle terminal
function M.toggle_terminal()
    if term_win ~= nil and vim.api.nvim_win_is_valid(term_win) then
        hide_terminal()
    else
        open_terminal()
    end
end

-- Setup function for plugin configuration
function M.setup(user_config)
    config = vim.tbl_extend('force', config, user_config or {})

    -- Create user command
    vim.api.nvim_create_user_command('ToggleTerm', M.toggle_terminal, {})

    -- Default keymapping
    vim.api.nvim_set_keymap('n', '<leader>t', ':ToggleTerm<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('t', '<leader>t', '<C-\\><C-n>:ToggleTerm<CR>', { noremap = true, silent = true })
end

return M
