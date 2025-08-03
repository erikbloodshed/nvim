local api = vim.api

local M = {}

local Terminal = {}
Terminal.__index = Terminal

-- Helpers
local function set_win_options(win, options)
    for opt, val in pairs(options) do
        api.nvim_set_option_value(opt, val, { win = win })
    end
end

local function set_buf_options(buf, options)
    for opt, val in pairs(options) do
        api.nvim_set_option_value(opt, val, { buf = buf })
    end
end

local function validate_config(cfg)
    if cfg.width and (cfg.width <= 0 or cfg.width > 1) then
        vim.notify("TermSwitch: 'width' must be between 0 and 1. Using default.", vim.log.levels.WARN)
        cfg.width = 0.8
    end
    if cfg.height and (cfg.height <= 0 or cfg.height > 1) then
        vim.notify("TermSwitch: 'height' must be between 0 and 1. Using default.", vim.log.levels.WARN)
        cfg.height = 0.8
    end
    local valid_borders = { none = true, single = true, double = true, rounded = true, solid = true, shadow = true }
    if cfg.border and not valid_borders[cfg.border] then
        vim.notify(string.format("TermSwitch: Invalid 'border' style '%s'. Using 'rounded'.", cfg.border),
            vim.log.levels.WARN)
        cfg.border = 'rounded'
    end
end

function Terminal:new(name, config)
    local default_cfg = {
        width = 0.8,
        height = 0.8,
        border = 'rounded',
        shell = nil,
        title = ' ' .. name:gsub("^%l", string.upper) .. ' ',
        filetype = 'terminal',
        auto_delete_on_close = false,
    }
    local merged_config = vim.tbl_extend('force', default_cfg, config or {})
    validate_config(merged_config)
    local obj = {
        name = name,
        config = merged_config,
        buf = nil,
        win = nil,
    }
    setmetatable(obj, self)
    return obj
end

function Terminal:get_float_config()
    local ui = api.nvim_list_uis()[1]
    local width = math.floor(ui.width * self.config.width)
    local height = math.floor(ui.height * self.config.height)
    return {
        relative = 'editor',
        width = width,
        height = height,
        col = math.floor((ui.width - width) / 2),
        row = math.floor((ui.height - height) / 2) - 1,
        style = 'minimal',
        border = self.config.border,
        title = self.config.title,
        title_pos = 'center',
    }
end

function Terminal:setup_window_options()
    if self:valid_win() then
        set_win_options(self.win, {
            number = false,
            relativenumber = false,
            signcolumn = 'no',
            wrap = false,
        })
    end
end

function Terminal:start_process()
    local cmd = self.config.shell and string.format("terminal %s", vim.fn.shellescape(self.config.shell)) or 'terminal'
    vim.cmd(cmd)
    self.buf = api.nvim_get_current_buf()

    set_buf_options(self.buf, {
        buflisted = false,
        bufhidden = 'wipe',
        filetype = self.config.filetype,
    })

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

function Terminal:valid_win()
    return self.win and api.nvim_win_is_valid(self.win)
end

function Terminal:is_current_window()
    return self:valid_win() and api.nvim_get_current_win() == self.win
end

function Terminal:open()
    if not self:valid_win() then
        local temp_buf = api.nvim_create_buf(false, true)
        self.win = api.nvim_open_win(temp_buf, true, self:get_float_config())
        self:setup_window_options()
        self:start_process()
        api.nvim_create_autocmd('WinClosed', {
            group = api.nvim_create_augroup('TermSwitch_' .. self.name .. '_Closed', { clear = true }),
            pattern = tostring(self.win),
            callback = function() self.win = nil end,
            once = true,
        })
    else
        api.nvim_set_current_win(self.win)
    end
    vim.cmd('startinsert')
end

function Terminal:hide()
    if self:valid_win() then
        api.nvim_win_close(self.win, false)
        self.win = nil
        pcall(api.nvim_clear_autocmds, { group = 'TermSwitch_' .. self.name .. '_Closed' })
    end
end

function Terminal:focus()
    if self:valid_win() then
        api.nvim_set_current_win(self.win)
        vim.cmd('startinsert')
        return true
    end
    return false
end

function Terminal:toggle()
    if self:is_current_window() then
        self:hide()
    elseif self:valid_win() then
        self:focus()
    else
        self:open()
    end
end

function Terminal:send(text)
    if self.buf and api.nvim_buf_is_valid(self.buf) and api.nvim_get_option_value('buftype', { buf = self.buf }) == 'terminal' then
        api.nvim_chan_send(api.nvim_buf_get_var(self.buf, 'terminal_job_id'), text)
    end
end

function Terminal:is_running()
    if self.buf and api.nvim_buf_is_valid(self.buf) then
        local job_id = api.nvim_buf_get_var(self.buf, 'terminal_job_id')
        return job_id and job_id > 0
    end
    return false
end

-- Terminal manager
local terminals = {}

function M.create_terminal(name, config)
    if terminals[name] then
        vim.notify(string.format("Terminal '%s' already exists", name), vim.log.levels.WARN)
        return terminals[name]
    end
    terminals[name] = Terminal:new(name, config or {})
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
    for name in pairs(terminals) do
        table.insert(names, name)
    end
    return names
end

function M.setup(user_config)
    local default_terminal = M.create_terminal('terminal', user_config or {})
    local python_terminal = M.create_terminal('python', {
        shell = 'python3.14',
        filetype = 'pyterm',
        auto_delete_on_close = true,
    })

    for _, def in ipairs({
        { name = 'ToggleTerm',   terminal = default_terminal, desc = 'Toggle floating terminal window' },
        { name = 'TogglePython', terminal = python_terminal,  desc = 'Toggle floating Python interpreter' },
    }) do
        api.nvim_create_user_command(def.name, function() def.terminal:toggle() end, { desc = def.desc })
    end

    api.nvim_create_user_command('ToggleTerminal', function(opts)
        local name = opts.args
        if name == '' then
            vim.notify("Usage: :ToggleTerminal <terminal_name>", vim.log.levels.ERROR)
            return
        end
        local term = terminals[name]
        if not term then
            vim.notify(string.format("Terminal '%s' not found. Create it first.", name), vim.log.levels.ERROR)
            return
        end
        term:toggle()
    end, {
        nargs = 1,
        complete = M.list_terminals,
        desc = 'Toggle any terminal by name',
    })

    local esc = api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true)

    for _, map in ipairs({
        { mode = 'n', lhs = '<leader>tt', rhs = function() default_terminal:open() end, desc = 'Toggle Terminal (Normal)' },
        { mode = 't', lhs = '<leader>tt', rhs = function()
            api.nvim_feedkeys(esc, 't', false); default_terminal:hide()
        end, desc = 'Toggle Terminal (Terminal)' },
        { mode = 'n', lhs = '<leader>tp', rhs = function() python_terminal:open() end,  desc = 'Toggle Python (Normal)' },
        { mode = 't', lhs = '<leader>tp', rhs = function()
            api.nvim_feedkeys(esc, 't', false); python_terminal:hide()
        end, desc = 'Toggle Python (Terminal)' },
    }) do
        vim.keymap.set(map.mode, map.lhs, map.rhs, { noremap = true, silent = true, desc = map.desc })
    end
end

M.Terminal = Terminal
return M
