-- luacheck: globals vim
local api = vim.api

local M = {}

---@class TerminalConfig
---@field width number
---@field height number
---@field border 'none' | 'single' | 'double' | 'rounded' | 'solid' | 'shadow'
---@field shell string | nil
---@field title string | nil
---@field filetype string | nil

---@class Terminal
---@field config TerminalConfig
---@field buf number | nil
---@field win number | nil
---@field name string
local Terminal = {}
Terminal.__index = Terminal

--- Creates a new Terminal instance
---@param name string Unique name for this terminal
---@param config TerminalConfig | nil Configuration for the terminal
---@return Terminal
function Terminal:new(name, config)
    local default_config = {
        width = 0.8,
        height = 0.8,
        border = 'rounded',
        shell = nil,
        title = nil,
        filetype = 'terminal',
    }

    local obj = {
        name = name,
        config = vim.tbl_extend('force', default_config, config or {}),
        buf = nil,
        win = nil,
    }

    -- Set default title if not provided
    if not obj.config.title then
        obj.config.title = ' ' .. name:gsub("^%l", string.upper) .. ' '
    end

    setmetatable(obj, self)
    return obj
end

--- @private
--- @return table float_config The configuration table for nvim_open_win.
function Terminal:get_float_config()
    local ui = api.nvim_list_uis()[1]
    local width = math.floor(ui.width * self.config.width)
    local height = math.floor(ui.height * self.config.height)
    local col = math.floor((ui.width - width) / 2)
    local row = math.floor((ui.height - height) / 2)

    return {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = self.config.border,
        title = self.config.title,
        title_pos = 'center',
    }
end

--- Ensures the terminal buffer exists and is valid.
--- @private
function Terminal:ensure_buffer()
    if self.buf == nil or not api.nvim_buf_is_valid(self.buf) then
        self.buf = api.nvim_create_buf(false, true)
        api.nvim_set_option_value('buflisted', false, { buf = self.buf })
        api.nvim_set_option_value('bufhidden', 'hide', { buf = self.buf })
        api.nvim_set_option_value('filetype', self.config.filetype, { buf = self.buf })
    end
end

--- @private
function Terminal:setup_window_options()
    if self.win and api.nvim_win_is_valid(self.win) then
        api.nvim_set_option_value('number', false, { win = self.win })
        api.nvim_set_option_value('relativenumber', false, { win = self.win })
        api.nvim_set_option_value('signcolumn', 'no', { win = self.win })
        api.nvim_set_option_value('wrap', false, { win = self.win })
        api.nvim_set_option_value('winhighlight', 'Normal:Normal,FloatBorder:FloatBorder', { win = self.win })
    end
end

--- @private
function Terminal:start_process()
    if api.nvim_get_option_value('buftype', { buf = self.buf }) ~= 'terminal' then
        api.nvim_set_current_buf(self.buf)

        local term_cmd = 'terminal'
        if self.config.shell then
            term_cmd = string.format("terminal %s", vim.fn.shellescape(self.config.shell))
        end

        vim.cmd(term_cmd)
        self.buf = api.nvim_get_current_buf()
    end
end

--- Check if we're currently in this terminal window
---@return boolean
function Terminal:is_current_window()
    local current_win = api.nvim_get_current_win()
    return self.win ~= nil
        and api.nvim_win_is_valid(self.win)
        and current_win == self.win
end

--- Check if the terminal window exists and is valid
---@return boolean
function Terminal:is_window_valid()
    return self.win ~= nil and api.nvim_win_is_valid(self.win)
end

--- Open the terminal window
function Terminal:open()
    self:ensure_buffer()

    if not self:is_window_valid() then
        local float_config = self:get_float_config()
        self.win = api.nvim_open_win(self.buf, true, float_config)
        self:setup_window_options()
        self:start_process()

        -- Set up autocmd to clean up when window is closed
        api.nvim_create_autocmd('WinClosed', {
            group = api.nvim_create_augroup('TermSwitch_' .. self.name .. '_Closed', { clear = true }),
            pattern = tostring(self.win),
            callback = function()
                self.win = nil
            end,
            once = true,
        })
    else
        api.nvim_set_current_win(self.win)
    end

    api.nvim_command('startinsert')
end

--- Hide the terminal window
function Terminal:hide()
    if self:is_window_valid() then
        api.nvim_win_close(self.win, false)
        self.win = nil
        -- Clear the autocmd since the window is now closed
        pcall(api.nvim_clear_autocmds, { group = 'TermSwitch_' .. self.name .. '_Closed' })
    end
end

--- Focus the terminal window if it exists
function Terminal:focus()
    if self:is_window_valid() then
        api.nvim_set_current_win(self.win)
        api.nvim_command('startinsert')
        return true
    end
    return false
end

--- Toggle the terminal window (open/hide/focus)
function Terminal:toggle()
    if self:is_current_window() then
        self:hide()
    elseif self:is_window_valid() then
        self:focus()
    else
        self:open()
    end
end

--- Send text to the terminal
---@param text string Text to send to the terminal
function Terminal:send(text)
    if self.buf and api.nvim_buf_is_valid(self.buf) then
        if api.nvim_get_option_value('buftype', { buf = self.buf }) == 'terminal' then
            api.nvim_chan_send(api.nvim_buf_get_var(self.buf, 'terminal_job_id'), text)
        end
    end
end

--- Check if the terminal process is running
---@return boolean
function Terminal:is_running()
    if self.buf and api.nvim_buf_is_valid(self.buf) then
        local job_id = api.nvim_buf_get_var(self.buf, 'terminal_job_id')
        return job_id and job_id > 0
    end
    return false
end

local default_global_config = {
    width = 0.8,
    height = 0.8,
    border = 'rounded',
}

local terminals = {}

--- Create a new terminal instance
---@param name string Unique name for the terminal
---@param config TerminalConfig | nil Configuration for the terminal
---@return Terminal
function M.create_terminal(name, config)
    if terminals[name] then
        vim.notify(string.format("Terminal '%s' already exists", name), vim.log.levels.WARN)
        return terminals[name]
    end

    -- Merge with global defaults
    local merged_config = vim.tbl_extend('force', default_global_config, config or {})
    terminals[name] = Terminal:new(name, merged_config)
    return terminals[name]
end

--- Get an existing terminal by name
---@param name string Name of the terminal
---@return Terminal | nil
function M.get_terminal(name)
    return terminals[name]
end

--- Remove a terminal instance
---@param name string Name of the terminal to remove
function M.remove_terminal(name)
    if terminals[name] then
        terminals[name]:hide()
        terminals[name] = nil
    end
end

--- List all terminal names
---@return string[]
function M.list_terminals()
    local names = {}
    for name, _ in pairs(terminals) do
        table.insert(names, name)
    end
    return names
end

function M.setup(user_config)
    -- Validate and merge global configuration
    if user_config then
        default_global_config = vim.tbl_extend('force', default_global_config, user_config)

        -- Basic validation
        if default_global_config.width <= 0 or default_global_config.width > 1 then
            vim.notify("TermSwitch: 'width' must be between 0 and 1. Using default.", vim.log.levels.WARN)
            default_global_config.width = 0.8
        end
        if default_global_config.height <= 0 or default_global_config.height > 1 then
            vim.notify("TermSwitch: 'height' must be between 0 and 1. Using default.", vim.log.levels.WARN)
            default_global_config.height = 0.8
        end
        local valid_borders = { 'none', 'single', 'double', 'rounded', 'solid', 'shadow' }
        if not vim.tbl_contains(valid_borders, default_global_config.border) then
            vim.notify(
                string.format("TermSwitch: Invalid 'border' style '%s'. Using 'rounded'.", default_global_config.border),
                vim.log.levels.WARN)
            default_global_config.border = 'rounded'
        end
    end

    -- Create default terminals for backward compatibility
    local default_terminal = M.create_terminal('terminal', { shell = nil })
    local python_terminal = M.create_terminal('python', { shell = 'python3.14' })

    -- Create commands
    api.nvim_create_user_command('ToggleTerm', function()
        default_terminal:toggle()
    end, { desc = 'Toggle floating terminal window' })

    api.nvim_create_user_command('TogglePython', function()
        python_terminal:toggle()
    end, { desc = 'Toggle floating Python interpreter' })

    -- Generic command to toggle any terminal
    api.nvim_create_user_command('ToggleTerminal', function(opts)
        local name = opts.args
        if name == '' then
            vim.notify("Usage: :ToggleTerminal <terminal_name>", vim.log.levels.ERROR)
            return
        end

        local terminal = terminals[name]
        if not terminal then
            vim.notify(
                string.format("Terminal '%s' not found. Create it first with require('termswitch').create_terminal('%s', config)",
                    name,
                    name), vim.log.levels.ERROR)
            return
        end

        terminal:toggle()
    end, {
        nargs = 1,
        complete = function()
            return M.list_terminals()
        end,
        desc = 'Toggle any terminal by name'
    })

    -- Set up default keymaps
    vim.keymap.set('n', '<leader>tt', ':ToggleTerm<CR>',
        { noremap = true, silent = true, desc = 'Toggle Terminal (Normal mode)' })
    vim.keymap.set('t', '<leader>tt', '<C-\\><C-n>:ToggleTerm<CR>',
        { noremap = true, silent = true, desc = 'Toggle Terminal (Terminal mode)' })

    vim.keymap.set('n', '<leader>tp', ':TogglePython<CR>',
        { noremap = true, silent = true, desc = 'Toggle Python interpreter (Normal mode)' })
    vim.keymap.set('t', '<leader>tp', '<C-\\><C-n>:TogglePython<CR>',
        { noremap = true, silent = true, desc = 'Toggle Python interpreter (Terminal mode)' })
end

-- Expose the Terminal class for advanced usage
M.Terminal = Terminal

return M
