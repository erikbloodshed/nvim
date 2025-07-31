local api = vim.api

local M = {}

local Terminal = {}
Terminal.__index = Terminal

function Terminal:new(name, config)
    local default_config = {
        width = 0.8,
        height = 0.8,
        border = 'rounded',
        shell = nil,
        title = nil,
        filetype = 'terminal',
        auto_delete_on_close = false,
    }

    local obj = {
        name = name,
        config = vim.tbl_extend('force', default_config, config or {}),
        buf = nil,
        win = nil,
    }

    if not obj.config.title then
        obj.config.title = ' ' .. name:gsub("^%l", string.upper) .. ' '
    end

    setmetatable(obj, self)
    return obj
end

function Terminal:get_float_config()
    local ui = api.nvim_list_uis()[1]
    local width = math.floor(ui.width * self.config.width)
    local height = math.floor(ui.height * self.config.height)
    local col = math.floor((ui.width - width) / 2)
    local row = math.floor((ui.height - height) / 2) - 1

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

function Terminal:ensure_buffer()
    if self.buf == nil or not api.nvim_buf_is_valid(self.buf) then
        self.buf = api.nvim_create_buf(false, true)
        api.nvim_set_option_value('buflisted', false, { buf = self.buf })
        api.nvim_set_option_value('bufhidden', 'hide', { buf = self.buf })
        api.nvim_set_option_value('filetype', self.config.filetype, { buf = self.buf })
    end
end

function Terminal:setup_window_options()
    if self.win and api.nvim_win_is_valid(self.win) then
        api.nvim_set_option_value('number', false, { win = self.win })
        api.nvim_set_option_value('relativenumber', false, { win = self.win })
        api.nvim_set_option_value('signcolumn', 'no', { win = self.win })
        api.nvim_set_option_value('wrap', false, { win = self.win })
        api.nvim_set_option_value('winhighlight', 'Normal:Normal,FloatBorder:FloatBorder', { win = self.win })
    end
end

function Terminal:start_process()
    if api.nvim_get_option_value('buftype', { buf = self.buf }) ~= 'terminal' then
        api.nvim_set_current_buf(self.buf)

        local term_cmd = 'terminal'
        if self.config.shell then
            term_cmd = string.format("terminal %s", vim.fn.shellescape(self.config.shell))
        end

        vim.cmd(term_cmd)
        self.buf = api.nvim_get_current_buf()

        if self.config.auto_delete_on_close then
            api.nvim_create_autocmd('TermClose', {
                group = api.nvim_create_augroup('TermSwitch_' .. self.name .. '_TermClose', { clear = true }),
                buffer = self.buf,
                callback = function()
                    vim.cmd('bdelete! ' .. self.buf)
                end,
                desc = 'Auto-delete terminal buffer on close for ' .. self.name
            })
        end
    end
end

function Terminal:is_current_window()
    local current_win = api.nvim_get_current_win()
    return self.win ~= nil
        and api.nvim_win_is_valid(self.win)
        and current_win == self.win
end

function Terminal:is_window_valid()
    return self.win ~= nil and api.nvim_win_is_valid(self.win)
end

function Terminal:open()
    self:ensure_buffer()

    if not self:is_window_valid() then
        local float_config = self:get_float_config()
        self.win = api.nvim_open_win(self.buf, true, float_config)
        self:setup_window_options()
        self:start_process()

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

function Terminal:hide()
    if self:is_window_valid() then
        api.nvim_win_close(self.win, false)
        self.win = nil
        pcall(api.nvim_clear_autocmds, { group = 'TermSwitch_' .. self.name .. '_Closed' })
    end
end

function Terminal:focus()
    if self:is_window_valid() then
        api.nvim_set_current_win(self.win)
        api.nvim_command('startinsert')
        return true
    end
    return false
end

function Terminal:toggle()
    if self:is_current_window() then
        self:hide()
    elseif self:is_window_valid() then
        self:focus()
    else
        self:open()
    end
end

function Terminal:send(text)
    if self.buf and api.nvim_buf_is_valid(self.buf) then
        if api.nvim_get_option_value('buftype', { buf = self.buf }) == 'terminal' then
            api.nvim_chan_send(api.nvim_buf_get_var(self.buf, 'terminal_job_id'), text)
        end
    end
end

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

function M.create_terminal(name, config)
    if terminals[name] then
        vim.notify(string.format("Terminal '%s' already exists", name), vim.log.levels.WARN)
        return terminals[name]
    end

    local merged_config = vim.tbl_extend('force', default_global_config, config or {})
    terminals[name] = Terminal:new(name, merged_config)
    return terminals[name]
end

function M.get_terminal(name)
    return terminals[name]
end

function M.remove_terminal(name)
    if terminals[name] then
        terminals[name]:hide()
        terminals[name] = nil
    end
end

function M.list_terminals()
    local names = {}
    for name, _ in pairs(terminals) do
        table.insert(names, name)
    end
    return names
end

function M.setup(user_config)
    if user_config then
        default_global_config = vim.tbl_extend('force', default_global_config, user_config)

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

    local default_terminal = M.create_terminal('terminal', { shell = nil })
    local python_terminal = M.create_terminal('python',
        { shell = 'python3.14', filetype = "pyterm", auto_delete_on_close = true })


    api.nvim_create_user_command('ToggleTerm', function()
        default_terminal:toggle()
    end, { desc = 'Toggle floating terminal window' })

    api.nvim_create_user_command('TogglePython', function()
        python_terminal:toggle()
    end, { desc = 'Toggle floating Python interpreter' })

    api.nvim_create_user_command('ToggleTerminal', function(opts)
        local name = opts.args
        if name == '' then
            vim.notify("Usage: :ToggleTerminal <terminal_name>", vim.log.levels.ERROR)
            return
        end

        local terminal = terminals[name]
        if not terminal then
            vim.notify(
                string.format(
                    "Terminal '%s' not found. Create it first with require('termswitch').create_terminal('%s', config)",
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

    local key = vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true)

    vim.keymap.set('n', '<leader>tt', function()
        default_terminal:open()
    end, { noremap = true, silent = true, desc = 'Toggle Terminal (Normal mode)' })

    vim.keymap.set('t', '<leader>tt', function()
        vim.api.nvim_feedkeys(key, "t", false)
        default_terminal:hide()
    end, { noremap = true, silent = true, desc = 'Toggle Terminal (Terminal mode)' })

    vim.keymap.set('n', '<leader>tp', function()
        python_terminal:open()
    end, { noremap = true, silent = true, desc = 'Toggle Python Terminal (Normal mode)' })

    vim.keymap.set('t', '<leader>tp', function()
        vim.api.nvim_feedkeys(key, "t", false)
        python_terminal:hide()
    end, { noremap = true, silent = true, desc = 'Toggle Python Terminal (Terminal mode)' })
end

M.Terminal = Terminal

return M
