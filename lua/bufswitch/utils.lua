local M = {}

local debounce_delay = 100
local debounce_timer = nil
local hide_timer = nil

-- Unified buffer check: mode='include' for should_include, 'special' for is_special
function M.check_buffer(config, bufnr, mode)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.fn.buflisted(bufnr) ~= 1 then
    return mode == 'include' and false or nil
  end

  local buf_type = vim.bo[bufnr].buftype
  local buf_filetype = vim.bo[bufnr].filetype
  local buf_name = vim.fn.bufname(bufnr)

  -- Exclude checks (for include mode)
  if mode == 'include' then
    if vim.tbl_contains(config.exclude_buftypes, buf_type) then return false end
    if vim.tbl_contains(config.exclude_filetypes, buf_filetype) then return false end

    if buf_name == "" and vim.fn.getbufvar(bufnr, '&modified') == 0 then
      local line_count = vim.api.nvim_buf_line_count(bufnr)
      if line_count > 1 then return true end
      if line_count == 1 then
        local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
        return first_line and #first_line > 0
      end
      return false
    end
    return true
  end

  -- Special checks (for special mode)
  for _, btype in ipairs(config.special_buftypes) do
    if buf_type == btype then return true end
  end
  for _, ftype in ipairs(config.special_filetypes) do
    if buf_filetype == ftype then return true end
  end
  for _, pattern in ipairs(config.special_bufname_patterns) do
    if buf_name:match(pattern) then return true end
  end
  if vim.fn.win_gettype() ~= "" then return true end
  return false
end

function M.is_special_buffer(config, bufnr)
  return M.check_buffer(config, bufnr, 'special')
end

function M.should_include_buffer(config, bufnr)
  return M.check_buffer(config, bufnr, 'include')
end

function M.cleanup_timer(timer)
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
    return true
  end
  return false
end

function M.set_debounce_delay(delay_ms)
  if type(delay_ms) == "number" and delay_ms > 0 then
    debounce_delay = delay_ms
    return true
  else
    vim.notify("Invalid debounce delay: must be a positive number", vim.log.levels.WARN)
    return false
  end
end

-- Simplified debounce using vim.defer_fn (no pcall overhead, single timer)
function M.debounce(fn)
  if M.cleanup_timer(debounce_timer) then
    debounce_timer = nil
  end

  debounce_timer = vim.uv.new_timer()
  if debounce_timer then
    debounce_timer:start(debounce_delay, 0, vim.schedule_wrap(function()
      local ok, err = pcall(fn)
      if not ok then
        vim.notify("Error in debounced function: " .. tostring(err), vim.log.levels.ERROR)
      end
      M.cleanup_timer(debounce_timer)
      debounce_timer = nil
    end))
  else
    vim.notify("Failed to create debounce timer", vim.log.levels.WARN)
    vim.schedule(fn)
  end
end

function M.get_hide_timer()
  return hide_timer
end

function M.set_hide_timer(timer)
  hide_timer = timer
end

return M
