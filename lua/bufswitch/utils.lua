local M = {}

-- Constants
local DEFAULT_DEBOUNCE_DELAY = 100
local MIN_DEBOUNCE_DELAY = 10
local MAX_DEBOUNCE_DELAY = 5000

-- Module state
local debounce_delay = DEFAULT_DEBOUNCE_DELAY
local debounce_timer = nil
local hide_timer = nil

-- Helper function to check if buffer has meaningful content
local function buffer_has_content(bufnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  if line_count > 1 then
    return true
  end

  if line_count == 1 then
    local success, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, 1, false)
    if success and lines[1] and #lines[1] > 0 then
      return true
    end
  end

  return false
end

-- Safe buffer operation wrapper
function M.safe_buffer_operation(operation, ...)
  local success, result = pcall(operation, ...)
  if not success then
    vim.notify(
      string.format("Buffer operation failed: %s", tostring(result)),
      vim.log.levels.WARN
    )
    return false, result
  end
  return true, result
end

function M.is_special_buffer(config, bufnr)
  if not config then
    vim.notify("is_special_buffer: config is nil", vim.log.levels.ERROR)
    return false
  end

  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return true -- Invalid buffers are considered special
  end

  local success, buf_type = pcall(function() return vim.bo[bufnr].buftype end)
  if not success then
    return true -- If we can't get buftype, treat as special
  end

  local success2, buf_filetype = pcall(function() return vim.bo[bufnr].filetype end)
  if not success2 then
    buf_filetype = ""
  end

  local success3, buf_name = pcall(vim.fn.bufname, bufnr)
  if not success3 then
    buf_name = ""
  end

  -- Check buffer types
  for _, btype in ipairs(config.special_buftypes or {}) do
    if buf_type == btype then
      return true
    end
  end

  -- Check file types
  for _, ftype in ipairs(config.special_filetypes or {}) do
    if buf_filetype == ftype then
      return true
    end
  end

  -- Check buffer name patterns
  for _, pattern in ipairs(config.special_bufname_patterns or {}) do
    if buf_name:match(pattern) then
      return true
    end
  end

  -- Check if it's a special window type
  local win_type_success, win_type = pcall(vim.fn.win_gettype)
  if win_type_success and win_type ~= "" then
    return true
  end

  return false
end

function M.should_include_buffer(config, bufnr)
  if not config then
    vim.notify("should_include_buffer: config is nil", vim.log.levels.ERROR)
    return false
  end

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local buf_listed_success, buf_listed = pcall(vim.fn.buflisted, bufnr)
  if not buf_listed_success or buf_listed ~= 1 then
    return false
  end

  local buf_name_success, buf_name = pcall(vim.fn.bufname, bufnr)
  if not buf_name_success then
    buf_name = ""
  end

  local buf_type_success, buf_type = pcall(function() return vim.bo[bufnr].buftype end)
  if not buf_type_success then
    buf_type = ""
  end

  local buf_filetype_success, buf_filetype = pcall(function() return vim.bo[bufnr].filetype end)
  if not buf_filetype_success then
    buf_filetype = ""
  end

  -- Check exclude lists
  if vim.tbl_contains(config.exclude_buftypes or {}, buf_type) then
    return false
  end

  if vim.tbl_contains(config.exclude_filetypes or {}, buf_filetype) then
    return false
  end

  -- Handle unnamed buffers
  if buf_name == "" then
    local modified_success, modified = pcall(vim.fn.getbufvar, bufnr, '&modified')
    if not modified_success then
      modified = 0
    end

    if modified == 0 then
      return buffer_has_content(bufnr)
    end
  end

  return true
end

function M.cleanup_timer(timer)
  if not timer then
    return false
  end

  local success = pcall(function()
    if not timer:is_closing() then
      timer:stop()
      -- Double-check before closing
      if not timer:is_closing() then
        timer:close()
      end
    end
  end)

  if not success then
    vim.notify("Warning: Failed to properly cleanup timer", vim.log.levels.WARN)
    return false
  end

  return true
end

function M.set_debounce_delay(delay_ms)
  if type(delay_ms) ~= "number" then
    vim.notify("Invalid debounce delay: must be a number", vim.log.levels.WARN)
    return false
  end

  if delay_ms < MIN_DEBOUNCE_DELAY or delay_ms > MAX_DEBOUNCE_DELAY then
    vim.notify(
      string.format("Debounce delay must be between %d and %d ms",
        MIN_DEBOUNCE_DELAY, MAX_DEBOUNCE_DELAY),
      vim.log.levels.WARN
    )
    return false
  end

  debounce_delay = delay_ms
  return true
end

function M.safe_command(cmd)
  if type(cmd) ~= "string" or cmd == "" then
    return false
  end

  local status, _ = pcall(vim.api.nvim_command, cmd)
  return status
end

function M.debounce(fn)
  if type(fn) ~= "function" then
    vim.notify("debounce: argument must be a function", vim.log.levels.ERROR)
    return
  end

  -- Cleanup existing timer
  if M.cleanup_timer(debounce_timer) then
    debounce_timer = nil
  end

  debounce_timer = vim.uv.new_timer()

  if not debounce_timer then
    vim.notify("Failed to create debounce timer, executing immediately", vim.log.levels.WARN)
    vim.schedule(fn)
    return
  end

  local success, err = pcall(function()
    debounce_timer:start(debounce_delay, 0, vim.schedule_wrap(function()
      local status, err_msg = pcall(fn)
      if not status then
        vim.notify("Error in debounced function: " .. tostring(err_msg), vim.log.levels.ERROR)
      end

      -- Cleanup timer after execution
      if M.cleanup_timer(debounce_timer) then
        debounce_timer = nil
      end
    end))
  end)

  if not success then
    vim.notify("Failed to start debounce timer: " .. tostring(err), vim.log.levels.ERROR)
    if M.cleanup_timer(debounce_timer) then
      debounce_timer = nil
    end
    -- Fallback to immediate execution
    vim.schedule(fn)
  end
end

function M.get_hide_timer()
  return hide_timer
end

function M.set_hide_timer(timer)
  hide_timer = timer
end

-- Utility function to get current debounce delay
function M.get_debounce_delay()
  return debounce_delay
end

-- Reset debounce delay to default
function M.reset_debounce_delay()
  debounce_delay = DEFAULT_DEBOUNCE_DELAY
  return true
end

return M
