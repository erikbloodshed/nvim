local M = {}
local utils = require("bufferswitch.utils")
local icons = require("ui.icons")
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local config = {
  hide_in_special = true, -- hide tabline in special buffers
  hide_timeout = 2000,    -- ms before hiding tabline
}

-- Enhanced color scheme with yellow selected tab
local function setup_highlight_groups()
  -- Selected tab - bright yellow background with dark text
  vim.api.nvim_set_hl(0, 'BufferSwitchSelected', {
    bg = '#ffd700', -- Golden yellow
    fg = '#1a1a1a', -- Dark text for contrast
    bold = true,
  })

  -- Inactive tabs - subtle dark theme
  vim.api.nvim_set_hl(0, 'BufferSwitchInactive', {
    bg = '#2a2a2a', -- Dark gray
    fg = '#888888', -- Light gray text
  })

  -- Hover effect (for future enhancement)
  vim.api.nvim_set_hl(0, 'BufferSwitchHover', {
    bg = '#3a3a3a', -- Slightly lighter gray
    fg = '#cccccc', -- Brighter text
  })

  -- Modified indicator
  vim.api.nvim_set_hl(0, 'BufferSwitchModified', {
    fg = '#ff6b6b', -- Red for modified indicator
    bold = true,
  })

  -- Separator between tabs
  vim.api.nvim_set_hl(0, 'BufferSwitchSeparator', {
    bg = '#1a1a1a', -- Background color
    fg = '#444444', -- Subtle separator
  })

  -- Fill area
  vim.api.nvim_set_hl(0, 'BufferSwitchFill', { bg = '#1a1a1a', fg = '#666666' })

  -- Right section (CWD)
  vim.api.nvim_set_hl(0, 'BufferSwitchRight', { link = "Directory" })
end

function M.format_buffer_name(bufnr, is_current)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return "[Invalid]"
  end

  local name = vim.fn.bufname(bufnr)
  local display_name = vim.fn.fnamemodify(name, ":t")

  -- Special handling for different buffer types
  if vim.bo[bufnr].buftype == "help" then
    return "[Help] " .. (display_name ~= "" and display_name or "help")
  elseif vim.bo[bufnr].buftype == "terminal" then
    return "[Term] " .. (display_name ~= "" and display_name:gsub("^term://.*//", "") or "terminal")
  elseif display_name == "" then
    display_name = "[No Name]"
  end

  -- Truncate very long names
  if #display_name > 25 then
    display_name = display_name:sub(1, 22) .. "..."
  end

  -- Determine the correct highlight group for the main text
  local base_hl = is_current and "BufferSwitchSelected" or "BufferSwitchInactive"

  -- Enhanced modified marker with custom highlight
  local modified_marker = ""
  if vim.bo[bufnr].modified then
    modified_marker = " %#BufferSwitchModified#●%#" .. base_hl .. "#"
  end

  -- Enhanced icon handling with better color matching
  local icon = ""
  if has_devicons then
    local ext = vim.fn.fnamemodify(name, ":e") or ""
    local devicon, icon_hl = devicons.get_icon(display_name, ext, { default = true })
    if devicon then
      local ok, original_hl = pcall(vim.api.nvim_get_hl, 0, { name = icon_hl })
      local tab_hl = vim.api.nvim_get_hl(0, { name = base_hl })
      local custom_icon_hl = "BufferSwitchIcon" .. (is_current and "Selected" or "Inactive")

      if ok and original_hl and original_hl.fg then
        local icon_fg = is_current and original_hl.fg or
          (original_hl.fg and string.format("#%06x",
            bit.band(original_hl.fg * 0.7, 0xffffff)) or "#888888")

        vim.api.nvim_set_hl(0, custom_icon_hl, {
          fg = icon_fg,
          bg = tab_hl.bg or "NONE",
        })
      end

      -- The fix: explicitly switch back to the base highlight group after the icon.
      icon = string.format("%%#%s#%s%%#%s# ", custom_icon_hl, devicon, base_hl)
    end
  end

  return string.format("%s%s%s", icon, display_name, modified_marker)
end

function M.update_tabline(buffer_list)
  -- Ensure highlight groups are set up
  setup_highlight_groups()

  local current_buf = vim.api.nvim_get_current_buf()
  local parts = {}

  for i, bufnr in ipairs(buffer_list) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local is_current = bufnr == current_buf
      local hl = is_current and "%#BufferSwitchSelected#" or "%#BufferSwitchInactive#"

      -- Add subtle padding and styling
      local entry = table.concat({
        hl,
        "  ", -- Left padding
        M.format_buffer_name(bufnr, is_current),
        "  ", -- Right padding
      })

      table.insert(parts, entry)

      -- Enhanced separator with better visual distinction
      if i < #buffer_list then
        table.insert(parts, "%#BufferSwitchSeparator#|") -- Thicker separator
      else
        -- For the last buffer, explicitly reset to fill highlight to prevent
        -- selected highlight from extending across remaining area
        table.insert(parts, "%#BufferSwitchFill#")
      end
    end
  end

  local left = table.concat(parts, "")

  -- Enhanced right section with better formatting
  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  local git_branch = ""

  -- Try to get git branch if available
  local ok, branch = pcall(function()
    return vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
  end)
  if ok and branch and branch ~= "" and not branch:match("fatal:") then
    git_branch = " " .. branch .. " "
  end

  local right = string.format(
    "%%=%s%%#BufferSwitchRight# %s%s ",
    "%#BufferSwitchFill#", -- Fill space
    git_branch ~= "" and (icons.git .. git_branch .. "📁 ") or "📁 ",
    cwd
  )

  -- Combine everything with proper fill - ensure fill highlight is active
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
