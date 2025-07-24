local M = {}

-- Store terminal buffer and window IDs
local term_buf = nil
local term_win = nil

-- Default configuration
local config = {
    width = 0.8,        -- 80% of editor width
    height = 0.8,       -- 80% of editor height
    border = 'rounded', -- Border style: 'none', 'single', 'double', 'rounded', 'solid', 'shadow'
}

-- Create floating window configuration
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

-- Create or show terminal
local function open_terminal()
    -- Create new terminal buffer if none exists
    if term_buf == nil or not vim.api.nvim_buf_is_valid(term_buf) then
        term_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_option_value('buflisted', false, { buf = term_buf })
        vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = term_buf })
    end

    -- Create floating window if it doesn't exist
    if term_win == nil or not vim.api.nvim_win_is_valid(term_win) then
        local float_config = get_float_config()
        term_win = vim.api.nvim_open_win(term_buf, true, float_config)

        -- Start terminal in the buffer if it's not already a terminal
        if vim.api.nvim_get_option_value('buftype', { buf = term_buf }) ~= 'terminal' then
            vim.cmd.terminal()
            term_buf = vim.api.nvim_get_current_buf()
        end

        -- Set window options
        vim.api.nvim_set_option_value('number', false, { win = term_win })
        vim.api.nvim_set_option_value('relativenumber', false, { win = term_win })
        vim.api.nvim_set_option_value('signcolumn', 'no', { win = term_win })
        vim.api.nvim_set_option_value('wrap', false, { win = term_win })

        -- Set up autocmd to clean up when window is closed
        vim.api.nvim_create_autocmd('WinClosed', {
            pattern = tostring(term_win),
            callback = function()
                term_win = nil
            end,
            once = true,
        })
    else
        -- If window exists, just focus it
        vim.api.nvim_set_current_win(term_win)
    end

    -- Enter terminal mode
    vim.api.nvim_command('startinsert')
end

-- Hide terminal
local function hide_terminal()
    if term_win ~= nil and vim.api.nvim_win_is_valid(term_win) then
        vim.api.nvim_win_close(term_win, false)
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
    vim.api.nvim_set_keymap('n', '<C-`>', ':ToggleTerm<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_keymap('t', '<C-`>', '<C-\\><C-n>:ToggleTerm<CR>', { noremap = true, silent = true })

    -- Additional escape keymapping for floating terminal
    vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', { noremap = true, silent = true })
end

return M
