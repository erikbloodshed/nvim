local M = {}

function M.get(c, o)
  local active_bg = o.transparent_background and c.none or c.mantle
  local inactive_bg = o.transparent_background and c.none or c.base

  return {
    NeoTreeDirectoryName = { fg = c.blue },
    NeoTreeDirectoryIcon = { fg = c.blue },
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
    NeoTreeGitIgnored = { fg = c.overlay0 },
    NeoTreeGitModified = { fg = c.yellow },
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
    NeoTreeWinSeparator = {
      fg = o.transparent_background and c.surface1 or c.base,
      bg = o.transparent_background and c.none or c.base,
    },
    NeoTreeStatusLineNC = { fg = c.mantle, bg = c.mantle },
  }
end

return M
