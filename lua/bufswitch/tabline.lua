local M = {}
local utils = require("bufswitch.utils")

-- Constants
local ELLIPSIS = "…"
local MIN_TAB_WIDTH = 5
local MAX_TAB_WIDTH = 15
local PADDING_WIDTH = 2

-- Cache for formatted names
local name_cache = {}
local cache_version = 0
local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

function M.invalidate_cache()
  cache_version = cache_version + 1
  if cache_version % 100 == 0 then
    name_cache = {}
  end
end

function M.format_buffer_name(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return '[Invalid]'
  end

  local cache_key = bufnr .. "_" .. cache_version
  if name_cache[cache_key] then
    return name_cache[cache_key]
  end

  local name = vim.fn.bufname(bufnr) or ""
  local display_name = name ~= "" and vim.fn.fnamemodify(name, ':t') or '[No Name]'
  local buf_type = vim.bo[bufnr].buftype or ""

  if buf_type == 'help' then
    display_name = "[Help] " .. (display_name ~= '[No Name]' and display_name or 'help')
  end

  local icon = ''
  if has_devicons and display_name ~= '[No Name]' and not display_name:match("^%[.*%]") then
    local ext = display_name:match('%.([^%.]+)$') or ''
    icon = devicons.get_icon(display_name, ext, { default = true }) or ''
  end

  local formatted_name = icon ~= '' and icon .. ' ' .. display_name or display_name
  name_cache[cache_key] = formatted_name
  return formatted_name
end

local function calculate_tab_widths(buffer_order, max_width)
  local num_buffers = #buffer_order
  if num_buffers == 0 then
    return {}
  end

  local separator_space = math.max(0, num_buffers - 1)
  local available_width = max_width - separator_space
  local tab_info = {}
  local total_desired_width = 0

  for _, bufnr in ipairs(buffer_order) do
    local full_name = M.format_buffer_name(bufnr)
    local desired_width = math.min(vim.fn.strwidth(full_name) + PADDING_WIDTH, MAX_TAB_WIDTH)
    tab_info[bufnr] = { full_name = full_name, desired_width = desired_width }
    total_desired_width = total_desired_width + desired_width
  end

  local tab_widths = {}
  if total_desired_width <= available_width then
    for bufnr, info in pairs(tab_info) do
      tab_widths[bufnr] = { display_name = info.full_name, width = info.desired_width }
    end
  else
    local target_width = math.max(math.floor(available_width / num_buffers), MIN_TAB_WIDTH)
    for bufnr, info in pairs(tab_info) do
      local display_name = info.full_name
      local actual_width = math.min(info.desired_width, target_width)
      local content_width = actual_width - PADDING_WIDTH
      if vim.fn.strwidth(display_name) > content_width and content_width > 1 then
        display_name = string.sub(display_name, 1, content_width - vim.fn.strwidth(ELLIPSIS)) .. ELLIPSIS
      end
      tab_widths[bufnr] = { display_name = display_name, width = actual_width }
    end
  end

  return tab_widths
end

function M.update_tabline_display(buffer_order)
  if not buffer_order or #buffer_order == 0 then
    vim.o.tabline = '%#TabLineFill#%='
    return
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local max_width = vim.o.columns > 0 and vim.o.columns or 80
  local tab_widths = calculate_tab_widths(buffer_order, max_width)
  local parts = {}

  for _, bufnr in ipairs(buffer_order) do
    local tab_info = tab_widths[bufnr]
    if not tab_info then
      goto continue
    end

    local label = string.format(' %-' .. (tab_info.width - PADDING_WIDTH) .. 's ', tab_info.display_name)
    table.insert(parts, bufnr == current_buf and '%#TabLineSel#' .. label or '%#TabLine#' .. label)
    ::continue::
  end

  vim.o.tabline = #parts > 0 and table.concat(parts, '%#TabLine#|') .. '%#TabLineFill#%=' or '%#TabLineFill#%='
end

function M.debounced_update_tabline(buffer_order)
  utils.debounce(function()
    pcall(M.update_tabline_display, buffer_order)
  end)
end

function M.manage_tabline(config, buffer_order)
  if config.hide_in_special and utils.is_special_buffer(config) then
    vim.o.showtabline = 0
    return
  end

  utils.cleanup_timer(utils.get_hide_timer())
  utils.set_hide_timer(nil)
  vim.o.showtabline = 2
  pcall(M.update_tabline_display, buffer_order)

  if config.hide_timeout and config.hide_timeout > 0 then
    local timer = vim.uv.new_timer()
    if timer then
      utils.set_hide_timer(timer)
      timer:start(config.hide_timeout, 0, vim.schedule_wrap(function()
        vim.o.showtabline = 0
        utils.cleanup_timer(timer)
        utils.set_hide_timer(nil)
      end))
    end
  end
end

function M.hide_tabline()
  vim.o.showtabline = 0
  utils.cleanup_timer(utils.get_hide_timer())
  utils.set_hide_timer(nil)
end

return M
