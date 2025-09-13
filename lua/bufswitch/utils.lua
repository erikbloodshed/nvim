local M = {}

local DEFAULT_DEBOUNCE_DELAY = 100
local MIN_DEBOUNCE_DELAY = 10
local MAX_DEBOUNCE_DELAY = 5000

local debounce_delay = DEFAULT_DEBOUNCE_DELAY
local debounce_timer = nil
local hide_timer = nil

function M.is_special_buffer(config, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return true
  end

  local buf_type = vim.bo[bufnr].buftype or ""
  local buf_filetype = vim.bo[bufnr].filetype or ""
  local buf_name = vim.fn.bufname(bufnr) or ""
  local win_type = vim.fn.win_gettype()

  return vim.tbl_contains(config.special_buftypes or {}, buf_type) or
    vim.tbl_contains(config.special_filetypes or {}, buf_filetype) or
    vim.iter(config.special_bufname_patterns or {}):any(function(pattern)
      return buf_name:match(pattern)
    end) or
    win_type ~= ""
end

function M.should_include_buffer(config, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.fn.buflisted(bufnr) ~= 1 then
    return false
  end

  local buf_type = vim.bo[bufnr].buftype or ""
  local buf_filetype = vim.bo[bufnr].filetype or ""
  local buf_name = vim.fn.bufname(bufnr) or ""
  local modified = vim.fn.getbufvar(bufnr, '&modified', 0)

  if vim.tbl_contains(config.exclude_buftypes or {}, buf_type) or
    vim.tbl_contains(config.exclude_filetypes or {}, buf_filetype) then
    return false
  end

  if buf_name == "" and modified == 0 then
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    return line_count > 1 or (line_count == 1 and #vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] > 0)
  end

  return true
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
  if type(delay_ms) ~= "number" or delay_ms < MIN_DEBOUNCE_DELAY or delay_ms > MAX_DEBOUNCE_DELAY then
    return false
  end
  debounce_delay = delay_ms
  return true
end

function M.safe_command(cmd)
  return type(cmd) == "string" and cmd ~= "" and pcall(vim.api.nvim_command, cmd)
end

function M.debounce(fn)
  M.cleanup_timer(debounce_timer)
  debounce_timer = vim.uv.new_timer()
  if not debounce_timer then
    vim.schedule(fn)
    return
  end

  debounce_timer:start(debounce_delay, 0, vim.schedule_wrap(function()
    pcall(fn)
    M.cleanup_timer(debounce_timer)
    debounce_timer = nil
  end))
end

function M.get_hide_timer() return hide_timer end

function M.set_hide_timer(timer) hide_timer = timer end

function M.get_debounce_delay() return debounce_delay end

function M.reset_debounce_delay()
  debounce_delay = DEFAULT_DEBOUNCE_DELAY
  return true
end

return M
