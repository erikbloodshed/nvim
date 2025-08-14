-- Plugin-specific highlights for Ayu Mirage theme
local M = {}

function M.get_highlights(palette)
  return {
    -- Blink.cmp (completion plugin)
    -- BlinkCmpMenuBorder = { link = "FloatBorder" },
    BlinkCmpLabelMatch = { fg = palette.syntax.tag, bold = true },
    BlinkCmpLabelDescription = { fg = palette.syntax.comment },
    BlinkCmpLabelDetail = { fg = palette.syntax.entity },
    BlinkCmpKind = { fg = palette.syntax.keyword },
    BlinkCmpKindText = { fg = palette.editor.fg },
    BlinkCmpKindMethod = { fg = palette.syntax.func },
    BlinkCmpKindFunction = { fg = palette.syntax.func },
    BlinkCmpKindConstructor = { fg = palette.syntax.entity },
    BlinkCmpKindField = { fg = palette.syntax.operator },
    BlinkCmpKindVariable = { fg = palette.editor.fg },
    BlinkCmpKindClass = { fg = palette.syntax.entity },
    BlinkCmpKindInterface = { fg = palette.syntax.entity },
    BlinkCmpKindModule = { fg = palette.syntax.tag },
    BlinkCmpKindProperty = { fg = palette.syntax.operator },
    BlinkCmpKindUnit = { fg = palette.syntax.constant },
    BlinkCmpKindValue = { fg = palette.syntax.constant },
    BlinkCmpKindEnum = { fg = palette.syntax.entity },
    BlinkCmpKindKeyword = { fg = palette.syntax.keyword },
    BlinkCmpKindSnippet = { fg = palette.syntax.special },
    BlinkCmpKindColor = { fg = palette.syntax.markup },
    BlinkCmpKindFile = { fg = palette.syntax.tag },
    BlinkCmpKindReference = { fg = palette.syntax.operator },
    BlinkCmpKindFolder = { fg = palette.syntax.tag },
    BlinkCmpKindEnumMember = { fg = palette.syntax.constant },
    BlinkCmpKindConstant = { fg = palette.syntax.constant },
    BlinkCmpKindStruct = { fg = palette.syntax.entity },
    BlinkCmpKindEvent = { fg = palette.syntax.special },
    BlinkCmpKindOperator = { fg = palette.syntax.operator },
    BlinkCmpKindTypeParameter = { fg = palette.syntax.operator },

    -- Neo-tree (file explorer)
    NeoTreeBufferNumber = { fg = palette.syntax.comment },
    NeoTreeCursorLine = { bg = palette.editor.line },
    NeoTreeDimText = { fg = palette.syntax.comment },
    NeoTreeDirectoryIcon = { fg = palette.syntax.entity },
    NeoTreeDirectoryName = { fg = palette.syntax.entity, bold = true },
    NeoTreeDotfile = { fg = palette.syntax.comment },
    NeoTreeFileIcon = { fg = palette.editor.fg },
    NeoTreeFileName = { fg = palette.editor.fg },
    NeoTreeFileNameOpened = { fg = palette.syntax.string },
    NeoTreeFilterTerm = { fg = palette.syntax.string, bold = true },
    NeoTreeFloatBorder = { link = "FloatBorder" },
    NeoTreeFloatTitle = { link = "Title" },
    NeoTreeTitleBar = { link = "Title" },

    -- Neo-tree Git integration
    NeoTreeGitAdded = { fg = palette.vcs.added },
    NeoTreeGitConflict = { fg = palette.vcs.removed },
    NeoTreeGitDeleted = { fg = palette.vcs.removed },
    NeoTreeGitIgnored = { fg = palette.syntax.comment },
    NeoTreeGitModified = { fg = palette.vcs.modified },
    NeoTreeGitUnstaged = { fg = palette.syntax.operator },
    NeoTreeGitUntracked = { fg = palette.syntax.tag },
    NeoTreeGitStaged = { fg = palette.vcs.added },

    -- Neo-tree UI elements
    NeoTreeHiddenByName = { fg = palette.syntax.comment },
    NeoTreeIndentMarker = { fg = palette.syntax.entity },
    NeoTreeExpander = { fg = palette.syntax.comment },
    NeoTreeNormal = { link = "Normal" },
    NeoTreeNormalNC = { link = "NormalNC" },
    NeoTreeSignColumn = { fg = palette.syntax.comment, bg = palette.editor.line },
    NeoTreeStats = { fg = palette.syntax.comment },
    NeoTreeStatsHeader = { fg = palette.syntax.tag, bold = true },
    NeoTreeStatusLine = { fg = palette.editor.line, bg = palette.ui.bg },
    NeoTreeStatusLineNC = { fg = palette.syntax.comment, bg = palette.editor.line },
    NeoTreeVertSplit = { fg = palette.ui.line },
    NeoTreeWinSeparator = { fg = palette.ui.line },
    NeoTreeRootName = { fg = palette.syntax.entity, bold = true },
    NeoTreeSymbolicLinkTarget = { fg = palette.syntax.tag },
    NeoTreeWindowsHidden = { fg = palette.syntax.comment },
  }
end

return M
