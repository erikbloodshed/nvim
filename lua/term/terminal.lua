local api, fn = vim.api, vim.fn
local backdrop = require('term.backdrop')

local get_ui_dimensions = function()
  local ui = api.nvim_list_uis()[1]
  if ui then
    return ui.width, ui.height
  end
  return 80, 24
end

local defaults = {
  width = 0.8,
  height = 0.8,
  border = 'rounded',
  filetype = 'nofile',
  auto_delete_on_close = false,
  open_in_file_dir = false,
  open = true,
}

local STATES = {
  CLOSED = 'closed',
  OPENING = 'opening',
  OPEN = 'open',
  CLOSING = 'closing',
  TERMINATED = 'terminated'
}

local Terminal = {}
Terminal.__index = Terminal

function Terminal:new(name, user_config)
  local merged = vim.tbl_extend('force', defaults, user_config or {})

  if not merged.title then
    merged.title = string.format(" %s ", name:gsub("^%l", string.upper))
  end

  local terminal = setmetatable({
    name = name,
    config = merged,
    state = STATES.CLOSED,
  }, self)

  terminal:_setup_global_events()
  return terminal
end

function Terminal:_setup_global_events()
  self._autocmd_group = api.nvim_create_augroup('Term_' .. self.name, { clear = true })

  -- Handle Neovim exit
  api.nvim_create_autocmd('VimLeavePre', {
    group = self._autocmd_group,
    callback = function()
      self:cleanup()
    end,
    desc = 'Cleanup terminal on Neovim exit'
  })

  api.nvim_create_autocmd('VimResized', {
    group = self._autocmd_group,
    callback = function()
      -- Schedule resize to avoid conflicts with other resize operations
      vim.schedule(function()
        self:_handle_resize()
      end)
    end,
    desc = 'Resize terminal window'
  })
end

function Terminal:_handle_resize()
  if self.state ~= STATES.OPEN or not self:_is_valid_window() then
    return
  end

  local new_config = self:_get_float_config()
  pcall(api.nvim_win_set_config, self.win, {
    width = new_config.width,
    height = new_config.height,
    col = new_config.col,
    row = new_config.row,
  })

  if self.backdrop_instance then
    backdrop.resize_backdrop(self.backdrop_instance)
  end
end

function Terminal:_get_float_config()
  local ui_w, ui_h = get_ui_dimensions()
  local width = math.floor(ui_w * self.config.width)
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

function Terminal:_ensure_buffer()
  if self.buf and api.nvim_buf_is_valid(self.buf) then
    return true
  end

  self.buf = api.nvim_create_buf(false, true)
  if not self.buf then
    return false
  end

  api.nvim_set_option_value("bufhidden", "hide", { buf = self.buf })
  api.nvim_set_option_value("filetype", self.config.filetype, { buf = self.buf })

  self:_setup_buffer_events()
  return true
end

function Terminal:_setup_buffer_events()
  if not self.buf then return end

  api.nvim_create_autocmd('TermClose', {
    group = self._autocmd_group,
    buffer = self.buf,
    callback = function()
      self.state = STATES.TERMINATED
      self.job_id = nil

      if self.config.auto_delete_on_close then
        vim.schedule(function()
          self:cleanup()
        end)
      end
    end,
    desc = 'Handle terminal process exit'
  })
end

function Terminal:_setup_window_events()
  if not self:_is_valid_window() then return end

  api.nvim_create_autocmd('WinClosed', {
    group = self._autocmd_group,
    pattern = tostring(self.win),
    callback = function()
      self:_transition_to_closed()
    end,
    once = true,
    desc = 'Handle terminal window close'
  })
end

function Terminal:_transition_to_closed()
  self.state = STATES.CLOSED
  self.win = nil
  backdrop.destroy_backdrop(self.backdrop_instance)
  self.backdrop_instance = nil
end

function Terminal:_is_valid_window()
  return self.win and api.nvim_win_is_valid(self.win)
end

function Terminal:_create_window()
  if not self:_ensure_buffer() then
    return false
  end

  self.backdrop_instance = backdrop.create_backdrop(self.name)

  self.win = api.nvim_open_win(self.buf, true, self:_get_float_config())
  if not self.win then
    backdrop.destroy_backdrop(self.backdrop_instance)
    self.backdrop_instance = nil
    return false
  end

  -- Schedule window option setting to ensure window is fully created
  vim.schedule(function()
    if self:_is_valid_window() then
      api.nvim_set_option_value("number", false, { win = self.win })
      api.nvim_set_option_value("relativenumber", false, { win = self.win })
      api.nvim_set_option_value("signcolumn", "no", { win = self.win })
      api.nvim_set_option_value("wrap", false, { win = self.win })
    end
  end)

  self:_setup_window_events()
  return true
end

function Terminal:_start_terminal_process()
  if self.state == STATES.TERMINATED then
    self.buf = nil
    self.job_id = nil
    if not self:_ensure_buffer() then
      return false
    end
  end

  local target_cwd = nil
  if self.config.open_in_file_dir then
    local file_dir = vim.fs.dirname(api.nvim_buf_get_name(0))
    if file_dir and fn.isdirectory(file_dir) == 1 then
      target_cwd = file_dir
    end
  end

  local cwd_changed = false
  local original_cwd = nil
  if target_cwd then
    original_cwd = fn.getcwd(0)
    if original_cwd ~= target_cwd then
      api.nvim_cmd({ cmd = 'lcd', args = { target_cwd } }, {})
      cwd_changed = true
    end
  end

  local term_cmd = { cmd = 'terminal' }
  if self.config.shell and self.config.shell ~= '' then
    term_cmd.args = { self.config.shell }
  end

  api.nvim_cmd(term_cmd, {})

  self.job_id = fn.getbufvar(self.buf, 'terminal_job_id', nil)

  vim.schedule(function()
    if api.nvim_buf_is_valid(self.buf) then
      api.nvim_set_option_value("buflisted", false, { buf = self.buf })
    end
  end)

  if cwd_changed and original_cwd then
    api.nvim_cmd({ cmd = 'lcd', args = { original_cwd } }, {})
  end

  return true
end

function Terminal:open()
  if self.state == STATES.OPEN then
    if self:_is_valid_window() then
      api.nvim_set_current_win(self.win)
      -- Schedule startinsert to ensure window focus is complete
      vim.schedule(function()
        api.nvim_cmd({ cmd = 'startinsert' }, {})
      end)
    end
    return
  end

  self.state = STATES.OPENING

  if not self:_is_valid_window() then
    if not self:_create_window() then
      self.state = STATES.CLOSED
      return
    end
  end

  local buftype = api.nvim_get_option_value('buftype', { buf = self.buf })
  if buftype ~= 'terminal' or self.state == STATES.TERMINATED then
    if not self:_start_terminal_process() then
      self.state = STATES.CLOSED
      return
    end
  end

  self.state = STATES.OPEN
  -- Schedule startinsert to ensure everything is properly set up
  vim.schedule(function()
    api.nvim_cmd({ cmd = 'startinsert' }, {})
  end)
end

function Terminal:hide()
  if self.state ~= STATES.OPEN then
    return
  end

  self.state = STATES.CLOSING

  if self:_is_valid_window() then
    api.nvim_win_close(self.win, false)
  end
end

function Terminal:toggle()
  if self.state == STATES.OPEN and self:_is_valid_window() and
    api.nvim_get_current_win() == self.win then
    self:hide()
  else
    self:open()
  end
end

function Terminal:is_running()
  return self.state == STATES.OPEN and self.job_id and self.job_id > 0
end

function Terminal:cleanup()
  if self:_is_valid_window() then
    pcall(api.nvim_win_close, self.win, true)
  end

  backdrop.destroy_backdrop(self.backdrop_instance)

  if self._autocmd_group then
    pcall(api.nvim_clear_autocmds, { group = self._autocmd_group })
  end

  if self.buf and api.nvim_buf_is_valid(self.buf) then
    pcall(api.nvim_cmd, { cmd = 'bdelete', args = { tostring(self.buf) }, bang = true }, {})
  end

  self.state = 'closed'
  self.win = nil
  self.buf = nil
  self.job_id = nil
  self.backdrop_instance = nil
end

return { Terminal = Terminal }
