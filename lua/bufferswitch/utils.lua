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

function M.darken_color(fg, a, bg)
  local p = "^#([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])$"

  local rgb = function(h)
    local r, g, b = string.match(string.lower(h), p)
    return { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) }
  end

  local b = rgb(bg)
  local f = rgb(fg)

  local blend = function(i)
    local r = (a * f[i] + ((1 - a) * b[i]))
    return math.floor(math.min(math.max(0, r), 255) + 0.5)
  end

  return string.format("#%02X%02X%02X", blend(1), blend(2), blend(3))
end

return M
