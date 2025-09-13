local M = {}

local hide_timer = nil

function M.is_special_buffer(config, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local buf_type = vim.bo[bufnr].buftype
  local buf_filetype = vim.bo[bufnr].filetype
  local buf_name = vim.fn.bufname(bufnr)

  for _, btype in ipairs(config.special_buftypes) do
    if buf_type == btype then
      return true
    end
  end

  for _, ftype in ipairs(config.special_filetypes) do
    if buf_filetype == ftype then
      return true
    end
  end

  for _, pattern in ipairs(config.special_bufname_patterns) do
    if buf_name:match(pattern) then
      return true
    end
  end

  return vim.fn.win_gettype() ~= ""
end

function M.should_include_buffer(config, bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.fn.buflisted(bufnr) ~= 1 then
    return false
  end

  if M.is_special_buffer(config, bufnr) then
    return false
  end

  local buf_name = vim.fn.bufname(bufnr)

  if buf_name == "" and vim.fn.getbufvar(bufnr, '&modified') == 0 then
    local line_count = vim.api.nvim_buf_line_count(bufnr)

    if line_count > 1 then
      return true
    elseif line_count == 1 then
      local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
      return first_line and #first_line > 0
    end

    return false
  end

  return true
end

function M.safe_command(cmd)
  return pcall(vim.api.nvim_command, cmd)
end

function M.start_hide_timer(timeout_ms, callback)
  M.stop_hide_timer()

  hide_timer = vim.uv.new_timer()
  if hide_timer then
    hide_timer:start(timeout_ms, 0, vim.schedule_wrap(callback))
  end
end

function M.stop_hide_timer()
  if hide_timer and not hide_timer:is_closing() then
    hide_timer:stop()
    hide_timer:close()
    hide_timer = nil
  end
end

return M
