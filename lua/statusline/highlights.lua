-- statusline/highlights.lua
local M = {}

--[[
  Default Highlight Definitions
--]]
local default_highlights = {
  StatusLineNormal = { fg = '#bd93f9', bg = 'NONE', bold = true },
  StatusLineInsert = { fg = '#50fa7b', bg = 'NONE', bold = true },
  StatusLineVisual = { fg = '#ff79c6', bg = 'NONE', bold = true },
  StatusLineCommand = { fg = '#f1fa8c', bg = 'NONE', bold = true },
  StatusLineReplace = { fg = '#ffb86c', bg = 'NONE', bold = true },
  StatusLineTerminal = { fg = '#8be9fd', bg = 'NONE', bold = true },
  StatusLineFile = { fg = '#f8f8f2', bg = 'NONE' },
  StatusLineModified = { fg = '#f1fa8c', bg = 'NONE', bold = true },
  StatusLineReadonly = { fg = '#6272a4', bg = 'NONE' },
  StatusLineGit = { fg = '#ffb86c', bg = 'NONE' },
  StatusLineInfo = { fg = '#6272a4', bg = 'NONE' },
  StatusLineDiagError = { fg = '#ff5555', bg = 'NONE' },
  StatusLineDiagWarn = { fg = '#f1fa8c', bg = 'NONE' },
  StatusLineDiagInfo = { fg = '#8be9fd', bg = 'NONE' },
  StatusLineDiagHint = { fg = '#50fa7b', bg = 'NONE' },
  StatusLineLSP = { fg = '#50fa7b', bg = 'NONE' },
}

--[[
  Setup highlight groups
--]]
function M.setup(custom_highlights)
  local highlights = vim.tbl_extend('force', default_highlights, custom_highlights or {})

  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

--[[
  Update a specific highlight group
--]]
function M.update_highlight(name, opts)
  vim.api.nvim_set_hl(0, name, opts)
end

--[[
  Get current highlight definition
--]]
function M.get_highlight(name)
  return vim.api.nvim_get_hl_by_name(name, true)
end

--[[
  Reset highlights to defaults
--]]
function M.reset()
  M.setup()
end

--[[
  Apply colorscheme-aware highlights
--]]
function M.apply_colorscheme_highlights()
  -- Get colors from current colorscheme if available
  local function get_color(group, attr)
    local hl = vim.api.nvim_get_hl_by_name(group, true)
    return hl[attr] and string.format('#%06x', hl[attr]) or nil
  end

  -- Try to extract colors from common highlight groups
  local normal_fg = get_color('Normal', 'foreground') or '#f8f8f2'
  local normal_bg = get_color('Normal', 'background') or 'NONE'
  local comment_fg = get_color('Comment', 'foreground') or '#6272a4'
  local error_fg = get_color('ErrorMsg', 'foreground') or '#ff5555'
  local warning_fg = get_color('WarningMsg', 'foreground') or '#f1fa8c'

  -- Dynamic highlights based on colorscheme
  local dynamic_highlights = {
    StatusLineFile = { fg = normal_fg, bg = normal_bg },
    StatusLineInfo = { fg = comment_fg, bg = normal_bg },
    StatusLineDiagError = { fg = error_fg, bg = normal_bg },
    StatusLineDiagWarn = { fg = warning_fg, bg = normal_bg },
  }

  M.setup(dynamic_highlights)
end

--[[
  Get all statusline highlight groups
--]]
function M.get_all_highlights()
  local result = {}
  for name, _ in pairs(default_highlights) do
    result[name] = M.get_highlight(name)
  end
  return result
end

--[[
  Validate highlight definition
--]]
function M.validate_highlight(opts)
  local valid_attrs = {
    'fg', 'bg', 'foreground', 'background',
    'bold', 'italic', 'underline', 'undercurl',
    'strikethrough', 'reverse', 'standout'
  }

  for key, _ in pairs(opts) do
    local valid = false
    for _, attr in ipairs(valid_attrs) do
      if key == attr then
        valid = true
        break
      end
    end

    if not valid then
      return false, string.format("Invalid highlight attribute: %s", key)
    end
  end

  return true
end

return M
