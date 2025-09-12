local api = vim.api
local fn = vim.fn
local config = require('term.config')
local utils = require('term.utils')
local backdrop = require('term.backdrop')

local Terminal = {}
Terminal.__index = Terminal

function Terminal:new(name, user_config)
  local merged = vim.tbl_extend('force', config.defaults, user_config or {})
  merged = config.validate_config(merged)

  if not merged.title then
    merged.title = utils.create_title(name)
  end

  return setmetatable({
    name = name,
    config = merged,
    buf = nil,
    win = nil,
    backdrop_instance = nil,
    _autocmd_group = nil,
    _buf_valid = false,
    _is_terminal = false,
    _job_id = nil,
    _resize_autocmd = nil,
  }, self)
end

function Terminal:get_float_config()
  local ui_w, ui_h = utils.get_ui_dimensions()
  local width = math.floor(ui_w * self.config.width) + (self.config._internal_width_padding or 2)
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

function Terminal:ensure_buffer()
  if self._buf_valid and self.buf and api.nvim_buf_is_valid(self.buf) then
    return
  end

  self.buf = api.nvim_create_buf(false, true)
  if not self.buf then
    error("Failed to create buffer for terminal: " .. tostring(self.name))
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
  })
end

function Terminal:create_backdrop()
  if self.backdrop_instance and backdrop.is_backdrop_valid(self.backdrop_instance) then return end
  self.backdrop_instance = backdrop.create_backdrop(self.name)
end

function Terminal:destroy_backdrop()
  if self.backdrop_instance then
    backdrop.destroy_backdrop(self.backdrop_instance)
    self.backdrop_instance = nil
  end
end

function Terminal:setup_auto_resize()
  if not self:is_valid_window() then return end

  self:clear_auto_resize()
  self._resize_autocmd = api.nvim_create_autocmd("VimResized", {
    callback = function()
      if not self:is_valid_window() then
        self:clear_auto_resize()
        return true
      end

      local new_cfg = self:get_float_config()
      local cfg_to_set = {
        relative = new_cfg.relative,
        width = new_cfg.width,
        height = new_cfg.height,
        col = new_cfg.col,
        row = new_cfg.row,
      }
      if new_cfg.style and new_cfg.style ~= "" then
        cfg_to_set.style = new_cfg.style
      end

      api.nvim_win_set_config(self.win, cfg_to_set)
      api.nvim_exec_autocmds("User", {
        pattern = "TerminalResized",
        modeline = false,
        data = { terminal_name = self.name, win = self.win },
      })
    end,
    desc = "Auto-resize floating terminal " .. self.name,
    group = self:_ensure_autocmd_group(),
  })
end

function Terminal:clear_auto_resize()
  if self._resize_autocmd then
    api.nvim_del_autocmd(self._resize_autocmd)
    self._resize_autocmd = nil
  end
end

function Terminal:setup_window_close_handler()
  if not self:is_valid_window() then return end
  local group = self:_ensure_autocmd_group()
  local winid = self.win

  api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = tostring(winid),
    callback = function()
      self.win = nil
      self:clear_auto_resize()
      self:destroy_backdrop()
    end,
    once = true,
  })
end

function Terminal:setup_auto_delete()
  if not (self.buf and api.nvim_buf_is_valid(self.buf)) then return end
  local group = self:_ensure_autocmd_group()
  local buf = self.buf

  api.nvim_create_autocmd('TermClose', {
    group = group,
    buffer = buf,
    callback = function()
      vim.schedule(function()
        if api.nvim_buf_is_valid(buf) then
          -- use proper nvim_cmd table form; bdelete with bang
          api.nvim_cmd({ cmd = 'bdelete', args = { tostring(buf) }, bang = true }, {})
        end
        self:invalidate_cache()
      end)
    end,
    desc = 'Auto-delete terminal buffer on close for ' .. self.name,
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

  if self._is_terminal then return true end

  local buftype = api.nvim_get_option_value('buftype', { buf = self.buf })
  if buftype == 'terminal' then
    self._is_terminal = true
    return true
  end
  return false
end

function Terminal:_teardown_window()
  if self:is_valid_window() then
    api.nvim_win_close(self.win, false)
  end
  self.win = nil
  self:clear_auto_resize()
  self:destroy_backdrop()
end

-- Start terminal process. Uses structured nvim_cmd table form for commands.
function Terminal:start_process(target_cwd)
  if self:is_terminal_buffer() then return end

  local prev_buf = api.nvim_get_current_buf()
  local cwd_changed = false
  local original_lcwd = nil

  if target_cwd and target_cwd ~= "" and fn.isdirectory(target_cwd) == 1 then
    original_lcwd = fn.getcwd(0)
    if original_lcwd ~= target_cwd then
      -- use lcd (window-local cwd) to avoid changing global cwd
      api.nvim_cmd({ cmd = 'lcd', args = { target_cwd } }, {})
      cwd_changed = true
    end
  end

  if not (self.buf and api.nvim_buf_is_valid(self.buf)) then
    self:ensure_buffer()
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

  local term_cmd = { cmd = 'terminal' }
  if self.config.shell and self.config.shell ~= '' then
    term_cmd.args = { self.config.shell }
  end

  api.nvim_cmd(term_cmd, {})

  self.buf = api.nvim_get_current_buf()
  self._buf_valid = true
  self._is_terminal = true

  local term_job = fn.getbufvar(self.buf, 'terminal_job_id', nil)
  if type(term_job) == 'number' and term_job > 0 then
    self._job_id = term_job
  else
    self._job_id = nil
  end

  if cwd_changed and original_lcwd then
    api.nvim_cmd({ cmd = 'lcd', args = { original_lcwd } }, {})
  end

  utils.set_buf_options(self.buf, {
    buflisted = false,
    bufhidden = 'hide',
    filetype = self.config.filetype,
  })

  if self.config.auto_delete_on_close then
    self:setup_auto_delete()
  end

  if prev_buf and api.nvim_buf_is_valid(prev_buf) and prev_buf ~= self.buf then
    api.nvim_set_current_buf(prev_buf)
  end
end

function Terminal:open()
  self:ensure_buffer()

  local target_cwd = nil
  if self.config.open_in_file_dir then
    local file_dir = fn.expand('%:p:h')
    if file_dir and fn.isdirectory(file_dir) == 1 then
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

  api.nvim_cmd({ cmd = 'startinsert' }, {})
end

function Terminal:hide()
  if not self:is_valid_window() then return end
  self:_teardown_window()
end

function Terminal:toggle()
  if self:is_valid_window() and api.nvim_get_current_win() == self.win then
    self:hide()
  else
    self:open()
  end
end

function Terminal:_get_job_id()
  if self._job_id and self._job_id > 0 then return self._job_id end
  if not self:is_terminal_buffer() then return nil end

  -- safe read without pcall using getbufvar default
  local job_id = fn.getbufvar(self.buf, 'terminal_job_id', nil)
  if type(job_id) == 'number' and job_id > 0 then
    self._job_id = job_id
    return job_id
  end
  return nil
end

function Terminal:is_running()
  local job_id = self:_get_job_id()
  if not job_id then return false end
  local res = fn.jobwait({ job_id }, 0)
  return res and res[1] == -1
end

function Terminal:invalidate_cache()
  self._buf_valid = false
  self._is_terminal = false
  self._job_id = nil
end

function Terminal:cleanup()
  self:hide()

  if self._autocmd_group then
    api.nvim_clear_autocmds({ group = self._autocmd_group })
    self._autocmd_group = nil
  end

  self:invalidate_cache()

  if self.buf and api.nvim_buf_is_valid(self.buf) then
    api.nvim_cmd({ cmd = 'bdelete', args = { tostring(self.buf) }, bang = true }, {})
  end
end

return { Terminal = Terminal }
