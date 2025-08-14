-- Plugin-specific highlights for Ayu Mirage theme
local M = {}

function M.get_highlights(p)
  return {
    -- Blink.cmp (completion plugin)
    -- BlinkCmpMenuBorder = { link = "FloatBorder" },
    BlinkCmpLabelMatch = { fg = p.syntax.tag, bold = true },
    BlinkCmpLabelDescription = { fg = p.syntax.comment },
    BlinkCmpLabelDetail = { fg = p.syntax.entity },
    BlinkCmpKind = { fg = p.syntax.keyword },
    BlinkCmpKindText = { fg = p.editor.fg },
    BlinkCmpKindMethod = { fg = p.syntax.func },
    BlinkCmpKindFunction = { fg = p.syntax.func },
    BlinkCmpKindConstructor = { fg = p.syntax.entity },
    BlinkCmpKindField = { fg = p.syntax.operator },
    BlinkCmpKindVariable = { fg = p.editor.fg },
    BlinkCmpKindClass = { fg = p.syntax.entity },
    BlinkCmpKindInterface = { fg = p.syntax.entity },
    BlinkCmpKindModule = { fg = p.syntax.tag },
    BlinkCmpKindProperty = { fg = p.syntax.operator },
    BlinkCmpKindUnit = { fg = p.syntax.constant },
    BlinkCmpKindValue = { fg = p.syntax.constant },
    BlinkCmpKindEnum = { fg = p.syntax.entity },
    BlinkCmpKindKeyword = { fg = p.syntax.keyword },
    BlinkCmpKindSnippet = { fg = p.syntax.special },
    BlinkCmpKindColor = { fg = p.syntax.markup },
    BlinkCmpKindFile = { fg = p.syntax.tag },
    BlinkCmpKindReference = { fg = p.syntax.operator },
    BlinkCmpKindFolder = { fg = p.syntax.tag },
    BlinkCmpKindEnumMember = { fg = p.syntax.constant },
    BlinkCmpKindConstant = { fg = p.syntax.constant },
    BlinkCmpKindStruct = { fg = p.syntax.entity },
    BlinkCmpKindEvent = { fg = p.syntax.special },
    BlinkCmpKindOperator = { fg = p.syntax.operator },
    BlinkCmpKindTypeParameter = { fg = p.syntax.operator },

    -- Neo-tree (file explorer)
    NeoTreeBufferNumber = { fg = p.syntax.comment },
    NeoTreeCursorLine = { bg = p.editor.line },
    NeoTreeDimText = { fg = p.syntax.comment },
    NeoTreeDirectoryIcon = { fg = p.syntax.entity },
    NeoTreeDirectoryName = { fg = p.syntax.entity, bold = true },
    NeoTreeDotfile = { fg = p.syntax.comment },
    NeoTreeFileIcon = { fg = p.editor.fg },
    NeoTreeFileName = { fg = p.editor.fg },
    NeoTreeFileNameOpened = { fg = p.syntax.string },
    NeoTreeFilterTerm = { fg = p.syntax.string, bold = true },
    NeoTreeFloatBorder = { link = "FloatBorder" },
    NeoTreeFloatTitle = { link = "Title" },
    NeoTreeTitleBar = { link = "Title" },

    -- Neo-tree Git integration
    NeoTreeGitAdded = { fg = p.vcs.added },
    NeoTreeGitConflict = { fg = p.vcs.removed },
    NeoTreeGitDeleted = { fg = p.vcs.removed },
    NeoTreeGitIgnored = { fg = p.syntax.comment },
    NeoTreeGitModified = { fg = p.vcs.modified },
    NeoTreeGitUnstaged = { fg = p.syntax.operator },
    NeoTreeGitUntracked = { fg = p.syntax.tag },
    NeoTreeGitStaged = { fg = p.vcs.added },

    -- Neo-tree UI elements
    NeoTreeHiddenByName = { fg = p.syntax.comment },
    NeoTreeIndentMarker = { fg = p.syntax.entity },
    NeoTreeExpander = { fg = p.syntax.comment },
    NeoTreeNormal = { link = "Normal" },
    NeoTreeNormalNC = { link = "NormalNC" },
    NeoTreeSignColumn = { fg = p.syntax.comment, bg = p.editor.line },
    NeoTreeStats = { fg = p.syntax.comment },
    NeoTreeStatsHeader = { fg = p.syntax.tag, bold = true },
    NeoTreeStatusLine = { fg = p.editor.line, bg = p.ui.bg },
    NeoTreeStatusLineNC = { fg = p.syntax.comment, bg = p.editor.line },
    NeoTreeVertSplit = { fg = p.ui.line },
    NeoTreeWinSeparator = { fg = p.ui.line },
    NeoTreeRootName = { fg = p.syntax.entity, bold = true },
    NeoTreeSymbolicLinkTarget = { fg = p.syntax.tag },
    NeoTreeWindowsHidden = { fg = p.syntax.comment },
  }
end

return M
