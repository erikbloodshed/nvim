local M = {}

local utils = require("bufferswitch.utils")
local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

local function get_buffer_name(bufnr)
  local name = vim.fn.bufname(bufnr)
  if name == "" then
    return "[No Name]"
  end
  -- Shorten the name to the basename for cleaner display
  return vim.fn.fnamemodify(name, ":t")
end

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

function M.update_tabline(buffer_list)
  local current_buf = vim.api.nvim_get_current_buf()
  local tabline_parts = {}

  -- Iterate through the buffer list to create tabline entries
  for _, bufnr in ipairs(buffer_list) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local name = get_buffer_name(bufnr)
      -- Highlight the current buffer
      local is_current = bufnr == current_buf
      local hl_group = is_current and "%#TabLineSel#" or "%#TabLine#"
      local entry = string.format("%s %s %%#TabLineFill#", hl_group, name)
      table.insert(tabline_parts, entry)
    end
  end

  -- Join entries with a separator and wrap with TabLineFill
  local tabline = "%#TabLineFill# " .. table.concat(tabline_parts, " | ") .. " %T"
  vim.o.tabline = tabline
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
