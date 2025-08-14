-- Base editor highlights for Ayu Mirage theme
local M = {}

function M.get_highlights(palette)
  return {
    -- Status line highlights
    StatusLineNormal = { fg = palette.syntax.constant, bold = true, reverse = true },
    StatusLineInsert = { fg = palette.syntax.string, bold = true, reverse = true },
    StatusLineVisual = { fg = palette.syntax.entity, bold = true, reverse = true },
    StatusLineCommand = { fg = palette.syntax.func, bold = true, reverse = true },
    StatusLineReplace = { fg = palette.syntax.markup, bold = true, reverse = true },
    StatusLineTerminal = { fg = palette.syntax.tag, bold = true, reverse = true },
    StatusLineFile = { fg = palette.editor.fg, bold = true },
    StatusLineModified = { fg = palette.syntax.func, bold = true },
    StatusLineReadonly = { fg = palette.syntax.comment },
    StatusLineGit = { fg = palette.syntax.operator },
    StatusLineInfo = { fg = palette.syntax.comment },
    StatusLineLabel = { fg = palette.syntax.comment },
    StatusLineValue = { fg = palette.syntax.constant },
    StatusLineDiagError = { fg = palette.common.error },
    StatusLineDiagWarn = { fg = palette.syntax.special },
    StatusLineDiagInfo = { fg = palette.syntax.entity },
    StatusLineDiagHint = { fg = palette.syntax.tag },
    StatusLineLSP = { fg = palette.syntax.string },
    StatusLine = { fg = palette.editor.fg, bg = palette.ui.bg },
    StatusLineNC = { fg = palette.syntax.comment, bg = palette.ui.bg },

    -- Core editor UI
    ColorColumn = { bg = palette.editor.line },
    Cursor = { fg = palette.editor.bg, bg = palette.editor.fg },
    CursorColumn = { bg = palette.editor.line },
    CursorLine = { bg = palette.editor.line },
    CursorLineNr = { fg = palette.editor.fg, bg = palette.editor.line },
    Directory = { fg = palette.syntax.entity, bold = true },
    EndOfBuffer = { fg = palette.editor.line },
    ErrorMsg = { fg = palette.common.error },
    FloatBorder = { fg = palette.syntax.entity, bg = palette.ui.bg },
    FoldColumn = { fg = palette.extra.fold_fg, bg = palette.extra.fold_bg },
    Folded = { fg = palette.extra.fold_fg, bg = palette.extra.fold_bg },
    IncSearch = { fg = palette.editor.bg, bg = palette.syntax.operator },
    LineNr = { fg = palette.extra.line_number_fg },
    MatchParen = { fg = palette.editor.bg, bg = palette.extra.match_paren_bg, bold = true },
    ModeMsg = { fg = palette.editor.fg },
    MoreMsg = { fg = palette.syntax.string },
    NonText = { fg = palette.syntax.comment },
    Normal = { fg = palette.editor.fg, bg = palette.editor.bg },
    NormalFloat = { fg = palette.ui.fg, bg = palette.ui.panel.bg },

    -- Popup menu
    Pmenu = { fg = palette.ui.fg, bg = palette.ui.panel.bg },
    PmenuSbar = { bg = palette.extra.pmenu_sbar_bg },
    PmenuSel = { fg = palette.editor.bg, bg = palette.syntax.entity },
    PmenuThumb = { bg = palette.extra.pmenu_thumb_bg },

    -- Search and selection
    Question = { fg = palette.syntax.string },
    QuickFixLine = { fg = palette.editor.bg, bg = palette.syntax.func },
    Search = { fg = palette.editor.bg, bg = palette.syntax.func },
    SignColumn = { fg = palette.syntax.comment, bg = palette.editor.bg },
    SpecialKey = { fg = palette.syntax.comment },

    -- Tabs
    TabLine = { fg = palette.ui.fg, bg = palette.ui.bg },
    TabLineFill = { bg = palette.ui.bg },
    TabLineSel = { fg = palette.editor.fg, bg = palette.ui.panel.bg },

    -- Miscellaneous
    Title = { fg = palette.extra.float_title_fg, bold = true },
    VertSplit = { fg = palette.ui.line },
    Visual = { bg = palette.editor.selection.active },
    VisualNOS = { bg = palette.editor.selection.inactive },
    WarningMsg = { fg = palette.syntax.special },
    Whitespace = { fg = palette.syntax.comment },
    WildMenu = { fg = palette.editor.bg, bg = palette.syntax.constant },
    WinSeparator = { fg = palette.ui.line },

    -- Diagnostic highlights
    DiagnosticError = { fg = palette.common.error },
    DiagnosticWarn = { fg = palette.syntax.special },
    DiagnosticInfo = { fg = palette.syntax.entity },
    DiagnosticHint = { fg = palette.syntax.tag },
    DiagnosticUnderlineError = { undercurl = true, sp = palette.common.error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = palette.syntax.special },
    DiagnosticUnderlineInfo = { undercurl = true, sp = palette.syntax.entity },
    DiagnosticUnderlineHint = { undercurl = true, sp = palette.syntax.tag },

    -- Git/Diff highlights
    DiffAdd = { fg = palette.vcs.added },
    DiffChange = { fg = palette.vcs.modified },
    DiffDelete = { fg = palette.vcs.removed },
    DiffText = { fg = palette.syntax.operator },
    GitSignsAdd = { fg = palette.vcs.added },
    GitSignsChange = { fg = palette.vcs.modified },
    GitSignsDelete = { fg = palette.vcs.removed },
  }
end

return M
