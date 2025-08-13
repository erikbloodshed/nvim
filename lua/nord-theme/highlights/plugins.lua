-- Plugin-specific highlights for Nord theme
local M = {}

function M.get_highlights(palette)
  return {
    -- Blink.cmp (completion plugin)
    BlinkCmpMenuBorder = { link = "FloatBorder" },
    BlinkCmpLabelMatch = { fg = palette.cyan.dim, bold = true },
    BlinkCmpLabelDescription = { fg = palette.gray5 },
    BlinkCmpLabelDetail = { fg = palette.cyan.base },
    BlinkCmpKind = { fg = palette.magenta.base },
    BlinkCmpKindText = { fg = palette.white0_normal },
    BlinkCmpKindMethod = { fg = palette.blue2 },
    BlinkCmpKindFunction = { fg = palette.blue2 },
    BlinkCmpKindConstructor = { fg = palette.cyan.base },
    BlinkCmpKindField = { fg = palette.orange.base },
    BlinkCmpKindVariable = { fg = palette.white0_normal },
    BlinkCmpKindClass = { fg = palette.cyan.base },
    BlinkCmpKindInterface = { fg = palette.cyan.base },
    BlinkCmpKindModule = { fg = palette.cyan.base },
    BlinkCmpKindProperty = { fg = palette.orange.base },
    BlinkCmpKindUnit = { fg = palette.magenta.base },
    BlinkCmpKindValue = { fg = palette.magenta.base },
    BlinkCmpKindEnum = { fg = palette.cyan.base },
    BlinkCmpKindKeyword = { fg = palette.blue1 },
    BlinkCmpKindSnippet = { fg = palette.yellow.base },
    BlinkCmpKindColor = { fg = palette.blue1 },
    BlinkCmpKindFile = { fg = palette.cyan.base },
    BlinkCmpKindReference = { fg = palette.orange.base },
    BlinkCmpKindFolder = { fg = palette.cyan.base },
    BlinkCmpKindEnumMember = { fg = palette.magenta.base },
    BlinkCmpKindConstant = { fg = palette.magenta.base },
    BlinkCmpKindStruct = { fg = palette.cyan.base },
    BlinkCmpKindEvent = { fg = palette.yellow.base },
    BlinkCmpKindOperator = { fg = palette.blue1 },
    BlinkCmpKindTypeParameter = { fg = palette.orange.base },

    -- Neo-tree (file explorer)
    NeoTreeBufferNumber = { fg = palette.gray5 },
    NeoTreeCursorLine = { bg = palette.gray1 },
    NeoTreeDimText = { fg = palette.gray5 },
    NeoTreeDirectoryIcon = { fg = palette.blue1 },
    NeoTreeDirectoryName = { fg = palette.blue1, bold = true },
    NeoTreeDotfile = { fg = palette.gray5 },
    NeoTreeFileIcon = { fg = palette.white0_normal },
    NeoTreeFileName = { fg = palette.white0_normal },
    NeoTreeFileNameOpened = { fg = palette.green.base },
    NeoTreeFilterTerm = { fg = palette.green.base, bold = true },
    NeoTreeFloatBorder = { link = "FloatBorder" },
    NeoTreeFloatTitle = { link = "Title" },
    NeoTreeTitleBar = { link = "Title" },

    -- Neo-tree Git integration
    NeoTreeGitAdded = { fg = palette.green.base },
    NeoTreeGitConflict = { fg = palette.red.bright },
    NeoTreeGitDeleted = { fg = palette.red.bright },
    NeoTreeGitIgnored = { fg = palette.gray5 },
    NeoTreeGitModified = { fg = palette.yellow.base },
    NeoTreeGitUnstaged = { fg = palette.orange.base },
    NeoTreeGitUntracked = { fg = palette.cyan.base },
    NeoTreeGitStaged = { fg = palette.green.base },

    -- Neo-tree UI elements
    NeoTreeHiddenByName = { fg = palette.gray5 },
    NeoTreeIndentMarker = { fg = palette.blue1 },
    NeoTreeExpander = { fg = palette.gray5 },
    NeoTreeNormal = { link = "Normal" },
    NeoTreeNormalNC = { link = "NormalNC" },
    NeoTreeSignColumn = { fg = palette.gray5, bg = palette.gray1 },
    NeoTreeStats = { fg = palette.gray5 },
    NeoTreeStatsHeader = { fg = palette.cyan.base, bold = true },
    NeoTreeStatusLine = { fg = palette.gray1, bg = palette.none },
    NeoTreeStatusLineNC = { fg = palette.gray5, bg = palette.gray1 },
    NeoTreeVertSplit = { fg = palette.gray3 },
    NeoTreeWinSeparator = { fg = palette.gray3 },
    NeoTreeRootName = { fg = palette.blue1, bold = true },
    NeoTreeSymbolicLinkTarget = { fg = palette.cyan.base },
    NeoTreeWindowsHidden = { fg = palette.gray5 },
  }
end

return M
