local M = {}
local utils = require("bufferswitch.utils")
local icons = require("ui.icons")
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local config = {
  hide_in_special = true, -- hide tabline in special buffers
  hide_timeout = 2000,    -- ms before hiding tabline
}

local colors = {
  rosewater = "#f5e0dc",
  flamingo = "#f2cdcd",
  pink = "#f5c2e7",
  mauve = "#cba6f7",
  red = "#f38ba8",
  maroon = "#eba0ac",
  peach = "#fab387",
  yellow = "#f9e2af",
  green = "#a6e3a1",
  teal = "#94e2d5",
  sky = "#89dceb",
  sapphire = "#74c7ec",
  blue = "#89b4fa",
  lavender = "#b4befe",
  text = "#cdd6f4",
  subtext1 = "#bac2de",
  subtext0 = "#a6adc8",
  overlay2 = "#9399b2",
  overlay1 = "#7f849c",
  overlay0 = "#6c7086",
  surface2 = "#585b70",
  surface1 = "#45475a",
  surface0 = "#313244",
  base = "#1e1e2e",
  mantle = "#181825",
  crust = "#11111b",
  none = "NONE",
}

local function setup_highlight_groups()
  vim.api.nvim_set_hl(0, 'BufferSwitchSelected', { bg = colors.base, fg = colors.text, bold = true, })
  vim.api.nvim_set_hl(0, 'BufferSwitchInactive', { bg = colors.mantle, fg = colors.overlay0, })
  vim.api.nvim_set_hl(0, 'BufferSwitchModified', { fg = '#ff6b6b' })
  vim.api.nvim_set_hl(0, 'BufferSwitchSeparator', { bg = colors.mantle, fg = colors.subtext0, })
  vim.api.nvim_set_hl(0, 'BufferSwitchFill', { bg = colors.mantle })
  vim.api.nvim_set_hl(0, 'BufferSwitchRight', { bg = colors.base, fg = colors.peach, bold = true, })
end

function M.format_buffer_name(bufnr, is_current)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return "[Invalid]"
  end

  local name = vim.fn.bufname(bufnr)
  local display_name = vim.fn.fnamemodify(name, ":t")

  if vim.bo[bufnr].buftype == "help" then
    return "[Help] " .. (display_name ~= "" and display_name or "help")
  elseif vim.bo[bufnr].buftype == "terminal" then
    return "[Term] " .. (display_name ~= "" and display_name:gsub("^term://.*//", "") or "terminal")
  elseif display_name == "" then
    display_name = "[No Name]"
  end

  if #display_name > 25 then
    display_name = display_name:sub(1, 22) .. "..."
  end

  local base_hl = is_current and "BufferSwitchSelected" or "BufferSwitchInactive"

  local modified_marker = ""
  if vim.bo[bufnr].modified then
    modified_marker = "%#BufferSwitchModified#●%#" .. base_hl .. "#"
  end

  local get_devicon = function()
    if has_devicons then
      local ext = vim.fn.fnamemodify(name, ":e") or ""

      local devicon, icon_hl = devicons.get_icon_color(display_name, ext)

      if devicon then
        local custom_icon_hl = "BufferSwitchIcon" .. (is_current and "Selected" or "Inactive")

        vim.api.nvim_set_hl(0, custom_icon_hl, {
          fg = is_current and icon_hl or colors.overlay0,
          bg = is_current and colors.base or colors.mantle,
        })

        return string.format("%%#%s#%s%%#%s# ", custom_icon_hl, devicon, base_hl)
      end
    end
    return ""
  end

  return string.format("%s%s%s", get_devicon(), display_name, modified_marker)
end

function M.update_tabline(buffer_list)
  setup_highlight_groups()

  local current_buf = vim.api.nvim_get_current_buf()
  local parts = {}

  for i, bufnr in ipairs(buffer_list) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local is_current = bufnr == current_buf
      local hl = is_current and "%#BufferSwitchSelected#" or "%#BufferSwitchInactive#"

      local entry = table.concat({
        hl,
        "  ",
        M.format_buffer_name(bufnr, is_current),
        "  ",
      })

      table.insert(parts, entry)

      if i < #buffer_list then
        table.insert(parts, "%#BufferSwitchSeparator#|")
      else
        table.insert(parts, "%#BufferSwitchFill#")
      end
    end
  end

  local left = table.concat(parts, "")

  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  local git_branch = ""

  local ok, branch = pcall(function()
    return vim.fn.system("git symbolic-ref --short HEAD"):gsub("\n", "")
  end)
  if ok and branch and branch ~= "" and not branch:match("fatal:") then
    git_branch = " " .. branch .. " "
  end

  local right = string.format(
    "%%=%s%%#BufferSwitchRight# %s%s ",
    "%#BufferSwitchFill#",
    git_branch ~= "" and (icons.git .. git_branch .. "📁 ") or "📁 ",
    cwd
  )

  vim.o.tabline = "%#BufferSwitchFill#" .. left .. right .. "%T"
end

function M.show_tabline_temporarily(_, buffer_order)
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
