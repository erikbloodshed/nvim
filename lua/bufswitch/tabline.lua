local M = {}

local utils = require("bufswitch.utils")

local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

function M.format_buffer_name(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return '[Invalid]'
  end

  local name = vim.fn.bufname(bufnr)
  local display_name = vim.fn.fnamemodify(name, ':t')
  local buf_type = vim.bo[bufnr].buftype

  if buf_type == 'help' then
    display_name = "[Help] " .. (display_name ~= '' and display_name or 'help')
  elseif display_name == '' then
    display_name = '[No Name]'
  end

  local ext = display_name:match('%.([^%.]+)$') or ''
  local icon = ''
  if has_devicons then
    icon = devicons.get_icon(display_name, ext, { default = true }) or ''
  end

  return (icon ~= '' and icon .. ' ' or '') .. display_name
end

-- Simplified: Truncate to max_tab_width uniformly (no complex width calc)
function M.update_tabline_display(buffer_order, max_tab_width)
  local current = vim.api.nvim_get_current_buf()
  local parts = {}
  local separator = '%#TabLine#|'

  for _, bufnr in ipairs(buffer_order) do
    local buf_label = M.format_buffer_name(bufnr)
    if vim.fn.strwidth(buf_label) > max_tab_width then
      buf_label = string.sub(buf_label, 1, max_tab_width - 1) .. "…"
    end

    local label = string.format(' %s ', buf_label)
    if bufnr == current then
      table.insert(parts, '%#TabLineSel#' .. label)
    else
      table.insert(parts, '%#TabLine#' .. label)
    end
  end

  if #parts > 0 then
    vim.o.tabline = table.concat(parts, separator) .. '%#TabLineFill#%='
  else
    vim.o.tabline = '%#TabLineFill#%='
  end
end

function M.debounced_update_tabline(buffer_order, max_tab_width)
  utils.debounce(function()
    M.update_tabline_display(buffer_order, max_tab_width or 15)
  end)
end

function M.manage_tabline(config, buffer_order)
  buffer_order = buffer_order or {}

  if config.hide_in_special and utils.is_special_buffer(config) then
    if vim.o.showtabline == 2 then
      vim.o.showtabline = 0
    end
    return
  end

  if utils.cleanup_timer(utils.get_hide_timer()) then
    utils.set_hide_timer(nil)
  end

  vim.o.showtabline = 2
  M.update_tabline_display(buffer_order, config.max_tab_width)

  local timer = vim.uv.new_timer()
  if timer then
    utils.set_hide_timer(timer)
    timer:start(config.hide_timeout, 0, vim.schedule_wrap(function()
      if vim.o.showtabline == 2 then
        vim.o.showtabline = 0
      end
      utils.cleanup_timer(utils.get_hide_timer())
      utils.set_hide_timer(nil)
    end))
  end
end

function M.hide_tabline()
  vim.o.showtabline = 0
  if utils.cleanup_timer(utils.get_hide_timer()) then
    utils.set_hide_timer(nil)
  end
end

return M
