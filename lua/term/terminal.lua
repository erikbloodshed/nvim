local api = vim.api
local config = require('term.config')
local utils = require('term.utils')
local backdrop = require('term.backdrop')

local Terminal = {}
Terminal.__index = Terminal

function Terminal:new(name, user_config)
  local merged_config = vim.tbl_extend('force', config.defaults, user_config or {})
  merged_config = config.validate_config(merged_config)

  if not merged_config.title then
    merged_config.title = utils.create_title(name)
  end

  local obj = {
    name = name,
    config = merged_config,
    buf = nil,
    win = nil,
    backdrop_instance = nil,
    _autocmd_group = nil,
    _buf_valid = false,
    _is_terminal = false,
    _job_id = nil,
    _resize_autocmd = nil,
  }
  setmetatable(obj, self)
  return obj
end

function Terminal:get_float_config()
  local ui_width, ui_height = utils.get_ui_dimensions()
  local width = math.floor(ui_width * self.config.width) + 2
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
    zindex = self.config.backdrop.enabled and 50 or nil,
  }
end

function Terminal:setup_auto_resize()
  if not self:is_valid_window() then
    return
  end

  self:clear_auto_resize()
  self._resize_autocmd = api.nvim_create_autocmd("VimResized", {
    callback = function()
      if not self:is_valid_window() then
        self:clear_auto_resize()
        return true
      end

      local new_config = self:get_float_config()

      local config_to_set = {
        relative = new_config.relative,
        width = new_config.width,
        height = new_config.height,
        col = new_config.col,
        row = new_config.row,
      }

      if new_config.style and new_config.style ~= "" then
        config_to_set.style = new_config.style
      end

      pcall(api.nvim_win_set_config, self.win, config_to_set)

      vim.api.nvim_exec_autocmds("User", {
        pattern = "TermSwitchResized",
        modeline = false,
        data = { terminal_name = self.name, win = self.win }
      })
    end,
    desc = "Auto-resize TermSwitch terminal " .. self.name,
    group = self:_ensure_autocmd_group()
  })
end

function Terminal:clear_auto_resize()
  if self._resize_autocmd then
    pcall(api.nvim_del_autocmd, self._resize_autocmd)
    self._resize_autocmd = nil
  end
end

function Terminal:ensure_buffer()
  if self._buf_valid and self.buf and api.nvim_buf_is_valid(self.buf) then
    return
  end

  self.buf = api.nvim_create_buf(false, true)
  if not self.buf then
    error("Failed to create buffer")
  end

  self._buf_valid = true
  self._is_terminal = false
  self._job_id = nil

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

function Terminal:create_backdrop()
  if not self.config.backdrop.enabled then
    return
  end

  if self.backdrop_instance and backdrop.is_backdrop_valid(self.backdrop_instance) then
    return
  end

  self.backdrop_instance = backdrop.create_backdrop(self.name)
end

function Terminal:destroy_backdrop()
  if self.backdrop_instance then
    backdrop.destroy_backdrop(self.backdrop_instance)
    self.backdrop_instance = nil
  end
end

function Terminal:start_process(target_cwd)
  if self:is_terminal_buffer() then return end

  local original_cwd = vim.fn.getcwd()
  local cwd_changed = false

  if target_cwd and target_cwd ~= original_cwd then
    vim.cmd('cd ' .. vim.fn.fnameescape(target_cwd))
    cwd_changed = true
  end

  local current_buf = api.nvim_get_current_buf()
  api.nvim_set_current_buf(self.buf)

  local cmd = self.config.shell and
    string.format("terminal %s", vim.fn.shellescape(self.config.shell)) or
    'terminal'

  vim.cmd(cmd)
  self.buf = api.nvim_get_current_buf()
  self._is_terminal = true
  self._buf_valid = true
  self._job_id = nil

  if cwd_changed then
    vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
  end

  utils.set_buf_options(self.buf, {
    buflisted = false,
    bufhidden = 'hide',
    filetype = self.config.filetype,
  })

  if self.config.auto_delete_on_close then
    self:setup_auto_delete()
  end

  if current_buf ~= self.buf and api.nvim_buf_is_valid(current_buf) then
    api.nvim_set_current_buf(current_buf)
  end
end

function Terminal:_ensure_autocmd_group()
  if not self._autocmd_group then
    self._autocmd_group = api.nvim_create_augroup('TermSwitch_' .. self.name, { clear = true })
  end
  return self._autocmd_group
end

function Terminal:setup_auto_delete()
  local group = self:_ensure_autocmd_group()

  api.nvim_create_autocmd('TermClose', {
    group = group,
    buffer = self.buf,
    callback = function()
      vim.schedule(function()
        if api.nvim_buf_is_valid(self.buf) then
          vim.cmd('bdelete! ' .. self.buf)
        end
        self:invalidate_cache()
      end)
    end,
    desc = 'Auto-delete terminal buffer on close for ' .. self.name
  })
end

function Terminal:setup_window_close_handler()
  local group = self:_ensure_autocmd_group()

  api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = tostring(self.win),
    callback = function()
      self.win = nil
      self:clear_auto_resize()
      self:destroy_backdrop()
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
  if not self._buf_valid or not self.buf or not api.nvim_buf_is_valid(self.buf) then
    self._buf_valid = false
    self._is_terminal = false
    return false
  end

  if self._is_terminal then
    return true
  end

  local success, buftype = pcall(api.nvim_get_option_value, 'buftype', { buf = self.buf })
  if success and buftype == 'terminal' then
    self._is_terminal = true
    return true
  end

  return false
end

function Terminal:open()
  self:ensure_buffer()

  local target_cwd = nil
  if self.config.open_in_file_dir then
    local file_dir = vim.fn.expand('%:p:h')
    if file_dir and vim.fn.isdirectory(file_dir) == 1 then
      target_cwd = file_dir
    end
  end

  if self:is_valid_window() then
    api.nvim_set_current_win(self.win)
  else
    self:create_backdrop()

    self.win = api.nvim_open_win(self.buf, true, self:get_float_config())
    self:setup_window_options()
    self:setup_window_close_handler()

    self:setup_auto_resize()
  end

  self:start_process(target_cwd)

  vim.cmd('startinsert')
end

function Terminal:hide()
  if not self:is_valid_window() then return end

  self:clear_auto_resize()

  api.nvim_win_close(self.win, false)
  self.win = nil

  self:destroy_backdrop()
end

function Terminal:toggle()
  local current_win = api.nvim_get_current_win()
  local win_valid = self.win and api.nvim_win_is_valid(self.win)

  if win_valid and current_win == self.win then
    self:hide()
  else
    self:open()
  end
end

function Terminal:_get_job_id()
  if self._job_id and self._job_id > 0 then
    return self._job_id
  end

  if not self:is_terminal_buffer() then
    return nil
  end

  local success, job_id = pcall(api.nvim_buf_get_var, self.buf, 'terminal_job_id')
  if success and job_id and job_id > 0 then
    self._job_id = job_id
    return job_id
  end

  return nil
end

function Terminal:is_running()
  return self:_get_job_id() ~= nil
end

function Terminal:invalidate_cache()
  self._buf_valid = false
  self._is_terminal = false
  self._job_id = nil
end

function Terminal:cleanup()
  self:hide()
  self:clear_auto_resize()
  self:destroy_backdrop()

  if self._autocmd_group then
    pcall(api.nvim_clear_autocmds, { group = self._autocmd_group })
    self._autocmd_group = nil
  end

  self:invalidate_cache()

  if self.buf and api.nvim_buf_is_valid(self.buf) then
    vim.cmd('bdelete! ' .. self.buf)
  end
end

return { Terminal = Terminal }
