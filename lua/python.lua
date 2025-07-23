-- Store terminal buffer and window IDs
local M = {}

local term_buf = nil
local term_win = nil

-- Create floating window configuration
local function get_float_config()
    local width = vim.o.columns
    local height = vim.o.lines
    local win_width = math.floor(width * 0.8)
    local win_height = math.floor(height * 0.8)
    local col = math.floor((width - win_width) / 2)
    local row = math.floor((height - win_height) / 2)

    return {
        relative = 'editor',
        width = win_width,
        height = win_height,
        col = col,
        row = row,
        style = 'minimal',
        border = 'rounded',
        title = ' Python ',
        title_pos = 'center',
    }
end

local function open_python()
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

        -- Start IPython in the buffer if it's not already a terminal
        if vim.api.nvim_get_option_value('buftype', { buf = term_buf }) ~= 'terminal' then
            vim.fn.jobstart('python3.14', { term = true })
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
    vim.cmd('startinsert')
end

local function hide_python()
    if term_win ~= nil and vim.api.nvim_win_is_valid(term_win) then
        vim.api.nvim_win_close(term_win, false)
        term_win = nil
    end
end

function M.toggle_python()
    if term_win ~= nil and vim.api.nvim_win_is_valid(term_win) then
        hide_python()
    else
        open_python()
    end
end

function M.init()
    -- Create user command
    vim.api.nvim_create_user_command('TogglePython', M.toggle_python, {})
    -- Set up keymapping
    vim.keymap.set('n', '<leader>`', M.toggle_python, { desc = 'Toggle Python terminal' })
    vim.keymap.set('t', '<leader>`', '<C-\\><C-n>:TogglePython<CR>', { noremap = true, silent = true })

    -- Additional escape keymapping for the terminal
    vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { noremap = true, silent = true })
end

return M
