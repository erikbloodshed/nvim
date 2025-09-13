local M = {}

local utils = require("bufferswitch.utils")
local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

function M.format_buffer_name(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return '[Invalid]'
  end

  local name = vim.fn.bufname(bufnr)
  local display_name = vim.fn.fnamemodify(name, ':t')

  if vim.bo[bufnr].buftype == 'help' then
    display_name = "[Help] " .. (display_name ~= '' and display_name or 'help')
  elseif display_name == '' then
    display_name = '[No Name]'
  end

  if has_devicons then
    local ext = display_name:match('%.([^%.]+)$') or ''
    local icon = devicons.get_icon(display_name, ext, { default = true })
    if icon then
      return icon .. ' ' .. display_name
    end
  end

  return display_name
end

function M.update_tabline(buffer_order)
  if not buffer_order or #buffer_order == 0 then
    vim.o.tabline = '%#TabLineFill#%='
    return
  end

  local current = vim.api.nvim_get_current_buf()
  local parts = {}
  local max_width = math.floor(vim.o.columns * 0.8)
  local available_per_buffer = math.max(math.floor(max_width / #buffer_order), 8)

  for _, bufnr in ipairs(buffer_order) do
    local buf_label = M.format_buffer_name(bufnr)

    if vim.fn.strwidth(buf_label) > available_per_buffer then
      buf_label = string.sub(buf_label, 1, available_per_buffer - 1) .. "…"
    end

    local padded_label = ' ' .. buf_label .. ' '

    if bufnr == current then
      table.insert(parts, '%#TabLineSel#' .. padded_label)
    else
      table.insert(parts, '%#TabLine#' .. padded_label)
    end
  end

  vim.o.tabline = table.concat(parts, '%#TabLine#|') .. '%#TabLineFill#%='
end

function M.show_tabline_temporarily(config, buffer_order)
  if config.hide_in_special and utils.is_special_buffer(config) then
    return
  end

  utils.stop_hide_timer()

  vim.o.showtabline = 2
  M.update_tabline(buffer_order)

  utils.start_hide_timer(config.hide_timeout, function()
    vim.o.showtabline = 0
  end)
end

function M.hide_tabline()
  vim.o.showtabline = 0
  utils.stop_hide_timer()
end

return M
