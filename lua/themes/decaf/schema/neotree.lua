local M = {}

function M.get(c, o)
  local transp = o.transparency
  local t = transp and c.none
  local active_bg = t or c.mantle
  local inactive_bg = t or c.base

  return {
    NeoTreeDirectoryName = { link = "Directory" },
    NeoTreeDirectoryIcon = { link = "Directory" },
    NeoTreeNormal = { fg = c.text, bg = active_bg },
    NeoTreeNormalNC = { fg = c.text, bg = active_bg },
    NeoTreeExpander = { fg = c.overlay0 },
    NeoTreeIndentMarker = { fg = c.overlay0 },
    NeoTreeRootName = { fg = c.blue, bold = true },
    NeoTreeSymbolicLinkTarget = { fg = c.pink },
    NeoTreeModified = { fg = c.peach },

    NeoTreeGitAdded = { fg = c.green },
    NeoTreeGitConflict = { fg = c.red },
    NeoTreeGitDeleted = { fg = c.red },
    NeoTreeGitModified = { fg = c.yellow },
    NeoTreeGitIgnored = { fg = c.overlay0 },
    NeoTreeGitUnstaged = { fg = c.red },
    NeoTreeGitUntracked = { fg = c.mauve },
    NeoTreeGitStaged = { fg = c.green },

    NeoTreeFloatBorder = { link = "FloatBorder" },
    NeoTreeFloatTitle = { link = "FloatTitle" },
    NeoTreeTitleBar = { fg = c.mantle, bg = c.blue },

    NeoTreeFileNameOpened = { fg = c.pink },
    NeoTreeDimText = { fg = c.overlay1 },
    NeoTreeFilterTerm = { fg = c.green, bold = true },
    NeoTreeTabActive = { bg = active_bg, fg = c.lavender, bold = true },
    NeoTreeTabInactive = { bg = inactive_bg, fg = c.overlay0 },
    NeoTreeTabSeparatorActive = { fg = active_bg, bg = active_bg },
    NeoTreeTabSeparatorInactive = { fg = inactive_bg, bg = inactive_bg },
    NeoTreeVertSplit = { fg = c.base, bg = inactive_bg },
    NeoTreeWinSeparator = { fg = transp and c.surface1 or c.base, bg = inactive_bg },
    NeoTreeStatusLineNC = { fg = c.mantle, bg = c.mantle },
  }
end

return M
