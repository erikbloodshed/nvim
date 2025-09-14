local api = vim.api
local fn = vim.fn
local backdrop = require('term.backdrop')

local defaults = {
  width = 0.8,
  height = 0.8,
  border = 'rounded',
  shell = nil,
  filetype = 'terminal',
  auto_delete_on_close = false,
  open_in_file_dir = false,
  open = true,
}

local Terminal = {}
Terminal.__index = Terminal

function Terminal:new(name, user_config)
  local config = vim.tbl_extend('force', defaults, user_config or {})

  if not config.title then
    config.title = name
  end

  return setmetatable({
    name = name,
    config = config,
    buf = nil,
    win = nil,
    backdrop_instance = nil,
    _autocmd_group = nil,
    _job_id = nil,
    _resize_autocmd = nil,
  }, self)
end

function Terminal:get_float_config()
  local ui = api.nvim_list_uis()[1]
  local ui_w, ui_h = ui.width, ui.height
  local width = math.floor(ui_w * self.config.width) + 2
  local height = math.floor(ui_h * self.config.height)

  return {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((ui_w - width) / 2),
    row = math.floor((ui_h - height) / 2) - 1,
    style = 'minimal',
    border = self.config.border,
    title = self.config.title,
    title_pos = 'center',
    zindex = 50,
  }
end

function Terminal:_ensure_autocmd_group()
  if not self._autocmd_group then
    self._autocmd_group = api.nvim_create_augroup('Term' .. self.name, { clear = true })
  end
  return self._autocmd_group
end

function Terminal:_create_buffer()
  if self.buf and api.nvim_buf_is_valid(self.buf) then
    return self.buf
  end

  self.buf = api.nvim_create_buf(false, true)
  if not self.buf then
    error("Failed to create buffer for terminal: " .. self.name)
  end

  return self.buf
end

function Terminal:_is_window_valid()
  return self.win and api.nvim_win_is_valid(self.win)
end

function Terminal:_setup_window()
  if self:_is_window_valid() then
    api.nvim_set_current_win(self.win)
    return
  end

  self:create_backdrop()
  self.win = api.nvim_open_win(self.buf, true, self:get_float_config())

  local win_opts = { number = false, relativenumber = false, signcolumn = 'no', wrap = false, }
  for opt, val in pairs(win_opts) do
    api.nvim_set_option_value(opt, val, { win = self.win })
  end

  self:_setup_window_handlers()
end

function Terminal:_setup_window_handlers()
  if not self:_is_window_valid() then return end

  local group = self:_ensure_autocmd_group()
  local winid = self.win

  -- Window close handler
  api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = tostring(winid),
    callback = function()
      self.win = nil
      self:_clear_resize_handler()
      self:destroy_backdrop()
    end,
    once = true,
  })

  -- Auto-resize handler
  self._resize_autocmd = api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      if not self:_is_window_valid() then
        self:_clear_resize_handler()
        return true
      end

      local cfg = self:get_float_config()
      api.nvim_win_set_config(self.win, {
        relative = cfg.relative,
        width = cfg.width,
        height = cfg.height,
        col = cfg.col,
        row = cfg.row,
      })

      api.nvim_exec_autocmds("User", {
        pattern = "TerminalResized",
        modeline = false,
        data = { terminal_name = self.name, win = self.win },
      })
    end,
    desc = "Auto-resize floating terminal " .. self.name,
  })
end

function Terminal:_clear_resize_handler()
  if self._resize_autocmd then
    api.nvim_del_autocmd(self._resize_autocmd)
    self._resize_autocmd = nil
  end
end

function Terminal:_start_terminal(target_cwd)
  local prev_buf = api.nvim_get_current_buf()

  -- Handle directory change
  local original_cwd = nil
  if target_cwd and fn.isdirectory(target_cwd) == 1 then
    original_cwd = fn.getcwd(0)
    if original_cwd ~= target_cwd then
      api.nvim_cmd({ cmd = 'lcd', args = { target_cwd } }, {})
    end
  end

  -- Start terminal
  local term_cmd = { cmd = 'terminal' }
  if self.config.shell and self.config.shell ~= '' then
    term_cmd.args = { self.config.shell }
  end
  api.nvim_cmd(term_cmd, {})

  -- Update buffer reference and cache job ID
  self.buf = api.nvim_get_current_buf()
  self._job_id = fn.getbufvar(self.buf, 'terminal_job_id', nil)

  -- Restore directory
  if original_cwd and original_cwd ~= target_cwd then
    api.nvim_cmd({ cmd = 'lcd', args = { original_cwd } }, {})
  end

  -- Set buffer options
  local buf_opts = {
    buflisted = false,
    bufhidden = 'hide',
    filetype = self.config.filetype,
  }

  for opt, val in pairs(buf_opts) do
    api.nvim_set_option_value(opt, val, { buf = self.buf })
  end

  -- Setup auto-delete if enabled
  if self.config.auto_delete_on_close then
    local group = self:_ensure_autocmd_group()
    api.nvim_create_autocmd('TermClose', {
      group = group,
      buffer = self.buf,
      callback = function()
        vim.schedule(function()
          if api.nvim_buf_is_valid(self.buf) then
            api.nvim_cmd({ cmd = 'bdelete', args = { tostring(self.buf) }, bang = true }, {})
          end
          self:_invalidate_cache()
        end)
      end,
      desc = 'Auto-delete terminal buffer on close for ' .. self.name,
    })
  end

  -- Restore previous buffer focus
  if prev_buf and api.nvim_buf_is_valid(prev_buf) and prev_buf ~= self.buf then
    api.nvim_set_current_buf(prev_buf)
  end
end

function Terminal:_invalidate_cache()
  self._job_id = nil
end

function Terminal:create_backdrop()
  if not self.backdrop_instance then
    self.backdrop_instance = backdrop.create_backdrop(self.name)
  end
end

function Terminal:destroy_backdrop()
  if self.backdrop_instance then
    backdrop.destroy_backdrop(self.backdrop_instance)
    self.backdrop_instance = nil
  end
end

function Terminal:open()
  self:_create_buffer()

  -- Determine target directory
  local target_cwd = nil
  if self.config.open_in_file_dir then
    local file_dir = vim.fs.dirname(api.nvim_buf_get_name(0))
    if file_dir and fn.isdirectory(file_dir) == 1 then
      target_cwd = file_dir
    end
  end

  self:_setup_window()

  -- Start terminal if buffer is not already a terminal
  local buftype = api.nvim_get_option_value('buftype', { buf = self.buf })
  if buftype ~= 'terminal' then
    self:_start_terminal(target_cwd)
  end

  api.nvim_cmd({ cmd = 'startinsert' }, {})
end

function Terminal:hide()
  if not self:_is_window_valid() then return end

  api.nvim_win_close(self.win, false)
  self.win = nil
  self:_clear_resize_handler()
  self:destroy_backdrop()
end

function Terminal:toggle()
  if self:_is_window_valid() and api.nvim_get_current_win() == self.win then
    self:hide()
  else
    self:open()
  end
end

function Terminal:is_running()
  local job_id = self._job_id
  if not job_id or job_id <= 0 then
    -- Try to get fresh job ID
    if self.buf and api.nvim_buf_is_valid(self.buf) then
      job_id = fn.getbufvar(self.buf, 'terminal_job_id', nil)
      if type(job_id) == 'number' and job_id > 0 then
        self._job_id = job_id
      else
        return false
      end
    else
      return false
    end
  end

  local res = fn.jobwait({ job_id }, 0)
  return res and res[1] == -1
end

function Terminal:cleanup()
  self:hide()

  if self._autocmd_group then
    api.nvim_clear_autocmds({ group = self._autocmd_group })
    self._autocmd_group = nil
  end

  self:_invalidate_cache()

  if self.buf and api.nvim_buf_is_valid(self.buf) then
    api.nvim_cmd({ cmd = 'bdelete', args = { tostring(self.buf) }, bang = true }, {})
    self.buf = nil
  end
end

return { Terminal = Terminal }
