local api = vim.api
local config = require('termswitch.config')
local utils = require('termswitch.utils')
local backdrop = require('termswitch.backdrop')

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
    backdrop_instance = nil, -- Backdrop instance for this terminal
    _autocmd_group = nil,    -- Single group instead of multiple
    _buf_valid = false,      -- Cache buffer validity
    _is_terminal = false,    -- Cache terminal state
    _job_id = nil,           -- Cache job ID
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
    zindex = self.config.backdrop.enabled and 50 or nil, -- Higher z-index when backdrop is enabled
  }
end

function Terminal:ensure_buffer()
  -- Use cached state first, but also verify the buffer still exists
  if self._buf_valid and self.buf and api.nvim_buf_is_valid(self.buf) then
    return -- Buffer exists and is valid
  end

  -- Buffer is invalid or doesn't exist, create new one
  self.buf = api.nvim_create_buf(false, true)
  if not self.buf then
    error("Failed to create buffer")
  end

  self._buf_valid = true
  self._is_terminal = false -- Reset terminal state for new buffer
  self._job_id = nil        -- Reset job ID for new buffer

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

  -- Create backdrop instance if it doesn't exist
  if not self.backdrop_instance then
    self.backdrop_instance = backdrop.create_backdrop(self.name, {
      opacity = self.config.backdrop.opacity,
      color = self.config.backdrop.color,
      zindex = 45, -- Lower than terminal window
    })
  end

  -- Create the backdrop
  self.backdrop_instance:create()
end

function Terminal:destroy_backdrop()
  if self.backdrop_instance then
    self.backdrop_instance:destroy()
    self.backdrop_instance = nil
  end
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
  self._is_terminal = true -- Mark as terminal buffer
  self._buf_valid = true
  self._job_id = nil       -- Reset job ID cache

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
        -- Invalidate cache since buffer will be deleted
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
      -- Destroy backdrop when window closes
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
  -- First ensure we have a valid buffer
  if not self._buf_valid or not self.buf or not api.nvim_buf_is_valid(self.buf) then
    self._buf_valid = false
    self._is_terminal = false
    return false
  end

  -- If we've cached that it's a terminal, trust that
  if self._is_terminal then
    return true
  end

  -- Check if it's actually a terminal buffer
  local success, buftype = pcall(api.nvim_get_option_value, 'buftype', { buf = self.buf })
  if success and buftype == 'terminal' then
    self._is_terminal = true
    return true
  end

  return false
end

function Terminal:open()
  self:ensure_buffer()

  if self:is_valid_window() then
    -- Window exists, just focus it
    api.nvim_set_current_win(self.win)
  else
    -- Create backdrop first (if enabled)
    self:create_backdrop()

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

  -- Destroy backdrop when hiding
  self:destroy_backdrop()
end

function Terminal:focus()
  if not self:is_valid_window() then return false end

  api.nvim_set_current_win(self.win)
  vim.cmd('startinsert')
  return true
end

function Terminal:toggle()
  -- Optimized: Single state check with cached results
  local current_win = api.nvim_get_current_win()
  local win_valid = self.win and api.nvim_win_is_valid(self.win)

  if win_valid and current_win == self.win then
    self:hide()
  elseif win_valid then
    self:focus()
  else
    self:open()
  end
end

function Terminal:_get_job_id()
  -- Return cached job_id if available
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

function Terminal:send(text)
  local job_id = self:_get_job_id()
  if job_id then
    vim.defer_fn(function()
      vim.fn.chansend(job_id, text)
    end, 75)
    return true
  end
  return false
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

  -- Clean up backdrop
  self:destroy_backdrop()

  -- Single autocmd group cleanup
  if self._autocmd_group then
    pcall(api.nvim_clear_autocmds, { group = self._autocmd_group })
    self._autocmd_group = nil
  end

  -- Reset cached state
  self:invalidate_cache()

  -- Clean up buffer if it exists
  if self.buf and api.nvim_buf_is_valid(self.buf) then
    vim.cmd('bdelete! ' .. self.buf)
  end
end

return { Terminal = Terminal }
