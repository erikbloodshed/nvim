local api = vim.api
local config = require('termswitch.config')
local utils = require('termswitch.utils')
local backdrop = require('termswitch.backdrop')

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
    backdrop_instance = nil, -- Backdrop instance for this terminal
    _autocmd_group = nil,    -- Single group instead of multiple
    _buf_valid = false,      -- Cache buffer validity
    _is_terminal = false,    -- Cache terminal state
    _job_id = nil,           -- Cache job ID
    _resize_autocmd = nil,   -- Track resize autocmd
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

function Terminal:setup_auto_resize()
  if not self:is_valid_window() then
    return
  end

  -- Clear any existing resize handler
  self:clear_auto_resize()

  -- Create autocmd for window resizing
  self._resize_autocmd = api.nvim_create_autocmd("VimResized", {
    callback = function()
      if not self:is_valid_window() then
        -- Window is no longer valid, clean up this autocmd
        self:clear_auto_resize()
        return true -- Remove this autocmd
      end

      -- Get new float config with updated dimensions
      local new_config = self:get_float_config()

      -- Update window configuration
      local config_to_set = {
        relative = new_config.relative,
        width = new_config.width,
        height = new_config.height,
        col = new_config.col,
        row = new_config.row,
      }

      -- Only include style if it's not empty (to avoid clearing existing style)
      if new_config.style and new_config.style ~= "" then
        config_to_set.style = new_config.style
      end

      -- Set the new window configuration
      pcall(api.nvim_win_set_config, self.win, config_to_set)

      -- Trigger a user event that other plugins can listen to
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

function Terminal:start_process(target_cwd)
  -- Check if terminal process is already running
  if self:is_terminal_buffer() then return end

  -- >> START of new logic <<
  local original_cwd = vim.fn.getcwd() -- Store the original working directory
  local cwd_changed = false
  -- >> FIX: Use the directory passed from the open() function

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
  self._is_terminal = true -- Mark as terminal buffer
  self._buf_valid = true
  self._job_id = nil       -- Reset job ID cache

  -- >> START of restoring directory <<
  -- Restore the original CWD if we changed it
  if cwd_changed then
    vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))
  end
  -- >> END of restoring directory <<

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
      -- Clear auto-resize when window closes
      self:clear_auto_resize()
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

  -- >> FIX: Determine the target CWD *before* creating any windows.
  -- At this point, the user's file buffer is still active.
  local target_cwd = nil
  if self.config.open_in_file_dir then
    local file_dir = vim.fn.expand('%:p:h')
    if file_dir and vim.fn.isdirectory(file_dir) == 1 then
      target_cwd = file_dir
    end
  end

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

    -- Setup auto-resize after window is created
    self:setup_auto_resize()
  end

  -- Start terminal process if needed
  self:start_process(target_cwd)

  -- Enter insert mode
  vim.cmd('startinsert')
end

function Terminal:hide()
  if not self:is_valid_window() then return end

  -- Clear auto-resize before closing window
  self:clear_auto_resize()

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

-- terminal.lua (New recommended implementation)
function Terminal:send(text, opts)
  opts = opts or {}
  local force_open = opts.open -- Add an option to open the terminal if not running

  local job_id = self:_get_job_id()

  if job_id then
    -- Job is already running, send the text immediately.
    -- The defer_fn is not necessary here and can be removed.
    vim.fn.chansend(job_id, text .. '\r')
    return true
  end

  if not force_open then
    vim.notify("TermSwitch: Terminal '" .. self.name .. "' is not running.", vim.log.levels.WARN)
    return false
  end

  -- Terminal is not yet running, so we need to open it and
  -- send the command once it's ready.
  self:open()

  -- Use a one-shot autocmd to send the command as soon as the terminal is ready.
  local group = self:_ensure_autocommd_group()
  api.nvim_create_autocommd('TermOpen', {
    group = group,
    buffer = self.buf,
    once = true,
    callback = function(args)
      local ready_job_id = api.nvim_buf_get_var(args.buf, 'terminal_job_id')
      if ready_job_id then
        vim.fn.chansend(ready_job_id, text .. '\r')
      end
    end,
    desc = 'Send command to ' .. self.name .. ' after open'
  })

  return true
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

  -- Clear auto-resize
  self:clear_auto_resize()

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
