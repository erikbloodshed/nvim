local api = vim.api
local config = require('termswitch.config')
local utils = require('termswitch.utils')

local Terminal = {}
Terminal.__index = Terminal

function Terminal:new(name, user_config)
    local merged_config = vim.tbl_extend('force', config.DEFAULT_CONFIG, user_config or {})
    merged_config = config.validate_config(merged_config)

    if not merged_config.title then
        merged_config.title = utils.create_title(name)
    end

    local obj = {
        name = name,
        config = merged_config,
        buf = nil,
        win = nil,
        _autocmd_groups = {}, -- Track autocmd groups for cleanup
    }
    setmetatable(obj, self)
    return obj
end

function Terminal:get_float_config()
    local ui_width, ui_height = utils.get_ui_dimensions()
    local width = math.floor(ui_width * self.config.width)
    local height = math.floor(ui_height * self.config.height)

    return {
        relative = 'editor',
        width = width,
        height = height,
        col = math.floor((ui_width - width) / 2),
        row = math.floor((ui_height - height) / 2) - 1,
        style = 'minimal',
        border = self.config.border,
        title = self.config.title,
        title_pos = 'center',
    }
end

function Terminal:ensure_buffer()
    if self.buf and api.nvim_buf_is_valid(self.buf) then
        return -- Buffer already exists and is valid
    end

    self.buf = api.nvim_create_buf(false, true)
    utils.set_buf_options(self.buf, {
        buflisted = false,
        bufhidden = 'hide',
        filetype = self.config.filetype,
    })
end

function Terminal:setup_window_options()
    if not self:is_valid_window() then return end

    utils.set_win_options(self.win, {
        number = false,
        relativenumber = false,
        signcolumn = 'no',
        wrap = false,
        winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
    })
end

function Terminal:start_process()
    -- Check if terminal process is already running
    if self:is_terminal_buffer() then return end

    local current_buf = api.nvim_get_current_buf()
    api.nvim_set_current_buf(self.buf)

    local cmd = self.config.shell and
        string.format("terminal %s", vim.fn.shellescape(self.config.shell)) or
        'terminal'

    vim.cmd(cmd)
    self.buf = api.nvim_get_current_buf()

    -- Set buffer options after terminal creation
    utils.set_buf_options(self.buf, {
        buflisted = false,
        bufhidden = 'hide',
        filetype = self.config.filetype,
    })

    -- Setup auto-delete if configured
    if self.config.auto_delete_on_close then
        self:setup_auto_delete()
    end

    -- Restore previous buffer if different
    if current_buf ~= self.buf and api.nvim_buf_is_valid(current_buf) then
        api.nvim_set_current_buf(current_buf)
    end
end

function Terminal:setup_auto_delete()
    local group_name = 'TermSwitch_' .. self.name .. '_TermClose'
    local group = api.nvim_create_augroup(group_name, { clear = true })
    self._autocmd_groups[group_name] = group

    api.nvim_create_autocmd('TermClose', {
        group = group,
        buffer = self.buf,
        callback = function()
            vim.schedule(function()
                if api.nvim_buf_is_valid(self.buf) then
                    vim.cmd('bdelete! ' .. self.buf)
                end
            end)
        end,
        desc = 'Auto-delete terminal buffer on close for ' .. self.name
    })
end

function Terminal:setup_window_close_handler()
    local group_name = 'TermSwitch_' .. self.name .. '_WinClosed'
    local group = api.nvim_create_augroup(group_name, { clear = true })
    self._autocmd_groups[group_name] = group

    api.nvim_create_autocmd('WinClosed', {
        group = group,
        pattern = tostring(self.win),
        callback = function()
            self.win = nil
        end,
        once = true,
    })
end

function Terminal:is_valid_window()
    return self.win and api.nvim_win_is_valid(self.win)
end

function Terminal:is_current_window()
    return self:is_valid_window() and api.nvim_get_current_win() == self.win
end

function Terminal:is_terminal_buffer()
    return self.buf and
        api.nvim_buf_is_valid(self.buf) and
        api.nvim_get_option_value('buftype', { buf = self.buf }) == 'terminal'
end

function Terminal:open()
    self:ensure_buffer()

    if self:is_valid_window() then
        -- Window exists, just focus it
        api.nvim_set_current_win(self.win)
    else
        -- Create new window
        self.win = api.nvim_open_win(self.buf, true, self:get_float_config())
        self:setup_window_options()
        self:setup_window_close_handler()
    end

    -- Start terminal process if needed
    self:start_process()

    -- Enter insert mode
    vim.cmd('startinsert')
end

function Terminal:hide()
    if not self:is_valid_window() then return end

    api.nvim_win_close(self.win, false)
    self.win = nil

    -- Clean up autocmd group
    local group_name = 'TermSwitch_' .. self.name .. '_WinClosed'
    if self._autocmd_groups[group_name] then
        pcall(api.nvim_clear_autocmds, { group = self._autocmd_groups[group_name] })
        self._autocmd_groups[group_name] = nil
    end
end

function Terminal:focus()
    if not self:is_valid_window() then return false end

    api.nvim_set_current_win(self.win)
    vim.cmd('startinsert')
    return true
end

function Terminal:toggle()
    if self:is_current_window() then
        self:hide()
    elseif self:is_valid_window() then
        self:focus()
    else
        self:open()
    end
end

function Terminal:send(text)
    if not self:is_terminal_buffer() then return false end

    local success, job_id = pcall(api.nvim_buf_get_var, self.buf, 'terminal_job_id')
    if success and job_id and job_id > 0 then
        vim.defer_fn(function()
            vim.fn.chansend(job_id, text)
        end, 75)
        return true
    end

    return false
end

function Terminal:is_running()
    if not self:is_terminal_buffer() then return false end

    local success, job_id = pcall(api.nvim_buf_get_var, self.buf, 'terminal_job_id')
    return success and job_id and job_id > 0
end

function Terminal:cleanup()
    self:hide()

    -- Clean up all autocmd groups
    for _, group in pairs(self._autocmd_groups) do
        pcall(api.nvim_clear_autocmds, { group = group })
    end
    self._autocmd_groups = {}

    -- Clean up buffer if it exists
    if self.buf and api.nvim_buf_is_valid(self.buf) then
        vim.cmd('bdelete! ' .. self.buf)
    end
end

return { Terminal = Terminal }
