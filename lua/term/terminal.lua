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
    -- Stored separately so open() can update display title without
    -- mutating config.title (which is used as the persistent label).
    _display_title = config.title,
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
    title = self._display_title,
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

  vim.wo[self.win].number = false
  vim.wo[self.win].relativenumber = false
  vim.wo[self.win].signcolumn = 'no'
  vim.wo[self.win].wrap = false

  -- Always clear any stale resize handler before registering a new one,
  -- since _setup_window can be called again after a hide/reopen cycle.
  self:_clear_resize_handler()
  self:_setup_window_handlers()
end

function Terminal:_setup_window_handlers()
  if not self:_is_window_valid() then return end

  local group = self:_ensure_autocmd_group()
  local winid = self.win

  -- Window close handler (fires when the user closes the float externally,
  -- e.g. via :q, rather than through Terminal:hide()).
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
    pcall(api.nvim_del_autocmd, self._resize_autocmd)
    self._resize_autocmd = nil
  end
end

function Terminal:_start_terminal(target_cwd, exec_cmd)
  local prev_buf = api.nvim_get_current_buf()

  -- Use `lcd` (local cd) instead of global `cd` to avoid briefly changing the
  -- working directory for every other window while the terminal is starting.
  local changed_dir = false
  if target_cwd and fn.isdirectory(target_cwd) == 1 then
    local current_lcd = fn.getcwd(fn.winnr())
    if current_lcd ~= target_cwd then
      api.nvim_cmd({ cmd = 'lcd', args = { target_cwd } }, {})
      changed_dir = true
    end
  end

  -- Build the :terminal command, preferring exec_cmd, then config.shell.
  local term_cmd = { cmd = 'terminal' }
  if exec_cmd and exec_cmd ~= '' then
    term_cmd.args = { exec_cmd }
  elseif self.config.shell and self.config.shell ~= '' then
    term_cmd.args = { self.config.shell }
  end
  api.nvim_cmd(term_cmd, {})

  -- Update buffer reference and eagerly cache the job ID.
  self.buf = api.nvim_get_current_buf()
  self._job_id = fn.getbufvar(self.buf, 'terminal_job_id', nil)

  -- Restore local directory now that the terminal job has been spawned.
  if changed_dir then
    api.nvim_cmd({ cmd = 'lcd', args = { '-' } }, {})
  end

  vim.bo[self.buf].buflisted = false
  vim.bo[self.buf].filetype = self.config.filetype

  if self.config.auto_delete_on_close then
    local group = self:_ensure_autocmd_group()
    api.nvim_create_autocmd('TermClose', {
      group = group,
      buffer = self.buf,
      callback = function()
        vim.schedule(function()
          if self.buf and api.nvim_buf_is_valid(self.buf) then
            pcall(api.nvim_cmd, { cmd = 'bdelete', args = { tostring(self.buf) }, bang = true }, {})
          end
          self:_invalidate_cache()
        end)
      end,
      desc = 'Auto-delete terminal buffer on close for ' .. self.name,
    })
  end

  -- Return focus to the caller's buffer (the terminal starts in insert mode
  -- anyway, so we switch back and let open() call startinsert).
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

-- open([exec_cmd])
-- Opens the terminal window. If exec_cmd is provided the terminal is
-- (re)started with that command; otherwise the existing shell session is
-- reused if still alive.
function Terminal:open(exec_cmd)
  local target_cwd = nil
  if self.config.open_in_file_dir then
    target_cwd = vim.fs.dirname(api.nvim_buf_get_name(0))
  end

  -- When an explicit command is requested, discard any existing session so
  -- the new command always gets a clean environment.
  if exec_cmd and self.buf and api.nvim_buf_is_valid(self.buf) then
    self:cleanup()
  end

  self:_create_buffer()
  self:_setup_window()

  local buftype = api.nvim_get_option_value('buftype', { buf = self.buf })
  if buftype ~= 'terminal' or exec_cmd then
    self:_start_terminal(target_cwd, exec_cmd)
  end

  -- Update the floating window's visible title to match _display_title
  -- (may have been changed by the Run command) without touching config.title.
  if self:_is_window_valid() then
    pcall(api.nvim_win_set_config, self.win, { title = self._display_title })
  end

  api.nvim_cmd({ cmd = 'startinsert' }, {})
end

-- hide() closes the window with force=true so it never silently fails
-- when the buffer has pending state (e.g. a running job).
function Terminal:hide()
  if not self:_is_window_valid() then return end

  pcall(api.nvim_win_close, self.win, true)
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

-- is_running() is a pure query — it no longer mutates _job_id as a side
-- effect. Job ID recovery is handled eagerly in _start_terminal instead.
function Terminal:is_running()
  local job_id = self._job_id
  if not job_id or job_id <= 0 then
    return false
  end
  local res = fn.jobwait({ job_id }, 0)
  return res ~= nil and res[1] == -1
end

-- is_open() exposes window visibility for external consumers such as
-- statusline integrations.
function Terminal:is_open()
  return self:_is_window_valid()
end

function Terminal:cleanup()
  -- Use pcall around hide() so that even if closing the window errors (e.g.
  -- last window in a tab), buffer deletion still runs.
  pcall(function() self:hide() end)

  if self._autocmd_group then
    pcall(api.nvim_clear_autocmds, { group = self._autocmd_group })
    self._autocmd_group = nil
  end

  self:_invalidate_cache()

  if self.buf and api.nvim_buf_is_valid(self.buf) then
    pcall(api.nvim_cmd, { cmd = 'bdelete', args = { tostring(self.buf) }, bang = true }, {})
    self.buf = nil
  end
end

return { Terminal = Terminal }
