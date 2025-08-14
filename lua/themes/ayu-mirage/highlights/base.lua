-- Base editor highlights for Ayu Mirage theme
local M = {}

function M.get_highlights(p)
  return {
    -- Status line highlights
    StatusLineNormal = { fg = p.syntax.constant, bold = true, reverse = true },
    StatusLineInsert = { fg = p.syntax.string, bold = true, reverse = true },
    StatusLineVisual = { fg = p.syntax.entity, bold = true, reverse = true },
    StatusLineCommand = { fg = p.syntax.func, bold = true, reverse = true },
    StatusLineReplace = { fg = p.syntax.markup, bold = true, reverse = true },
    StatusLineTerminal = { fg = p.syntax.tag, bold = true, reverse = true },
    StatusLineFile = { fg = p.editor.fg, bold = true },
    StatusLineModified = { fg = p.syntax.func, bold = true },
    StatusLineReadonly = { fg = p.syntax.comment },
    StatusLineGit = { fg = p.syntax.operator },
    StatusLineInfo = { fg = p.syntax.comment },
    StatusLineLabel = { fg = p.syntax.comment },
    StatusLineValue = { fg = p.syntax.constant },
    StatusLineDiagError = { fg = p.common.error },
    StatusLineDiagWarn = { fg = p.syntax.special },
    StatusLineDiagInfo = { fg = p.syntax.entity },
    StatusLineDiagHint = { fg = p.syntax.tag },
    StatusLineLSP = { fg = p.syntax.string },
    StatusLine = { fg = p.editor.fg, bg = p.ui.bg },
    StatusLineNC = { fg = p.syntax.comment, bg = p.ui.bg },

    -- Core editor UI
    ColorColumn = { bg = p.editor.line },
    Cursor = { fg = p.editor.bg, bg = p.editor.fg },
    CursorColumn = { bg = p.editor.line },
    CursorLine = { bg = p.editor.line },
    CursorLineNr = { fg = p.editor.fg, bg = p.editor.line },
    Directory = { fg = p.syntax.entity, bold = true },
    EndOfBuffer = { fg = p.editor.line },
    ErrorMsg = { fg = p.common.error },
    FloatBorder = { fg = p.syntax.entity, bg = p.ui.bg },
    FoldColumn = { fg = p.extra.fold_fg, bg = p.extra.fold_bg },
    Folded = { fg = p.extra.fold_fg, bg = p.extra.fold_bg },
    IncSearch = { fg = p.editor.bg, bg = p.syntax.operator },
    LineNr = { fg = p.extra.line_number_fg },
    MatchParen = { fg = p.editor.bg, bg = p.extra.match_paren_bg, bold = true },
    ModeMsg = { fg = p.editor.fg },
    MoreMsg = { fg = p.syntax.string },
    NonText = { fg = p.syntax.comment },
    Normal = { fg = p.editor.fg, bg = p.editor.bg },
    NormalFloat = { fg = p.ui.fg, bg = p.ui.panel.bg },

    -- Popup menu
    Pmenu = { fg = p.ui.fg, bg = p.ui.panel.bg },
    PmenuSbar = { bg = p.extra.pmenu_sbar_bg },
    PmenuSel = { fg = p.editor.bg, bg = p.syntax.entity },
    PmenuThumb = { bg = p.extra.pmenu_thumb_bg },

    -- Search and selection
    Question = { fg = p.syntax.string },
    QuickFixLine = { fg = p.editor.bg, bg = p.syntax.func },
    Search = { fg = p.editor.bg, bg = p.syntax.func },
    SignColumn = { fg = p.syntax.comment, bg = p.editor.bg },
    SpecialKey = { fg = p.syntax.comment },

    -- Tabs
    TabLine = { fg = p.ui.fg, bg = p.ui.bg },
    TabLineFill = { bg = p.ui.bg },
    TabLineSel = { fg = p.editor.fg, bg = p.ui.panel.bg },

    -- Miscellaneous
    Title = { fg = p.extra.float_title_fg, bold = true },
    VertSplit = { fg = p.ui.line },
    Visual = { bg = p.editor.selection.active },
    VisualNOS = { bg = p.editor.selection.inactive },
    WarningMsg = { fg = p.syntax.special },
    Whitespace = { fg = p.syntax.comment },
    WildMenu = { fg = p.editor.bg, bg = p.syntax.constant },
    WinSeparator = { fg = p.ui.line },

    -- Diagnostic highlights
    DiagnosticError = { fg = p.common.error },
    DiagnosticWarn = { fg = p.syntax.special },
    DiagnosticInfo = { fg = p.syntax.entity },
    DiagnosticHint = { fg = p.syntax.tag },
    DiagnosticUnderlineError = { undercurl = true, sp = p.common.error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = p.syntax.special },
    DiagnosticUnderlineInfo = { undercurl = true, sp = p.syntax.entity },
    DiagnosticUnderlineHint = { undercurl = true, sp = p.syntax.tag },

    -- Git/Diff highlights
    DiffAdd = { fg = p.vcs.added },
    DiffChange = { fg = p.vcs.modified },
    DiffDelete = { fg = p.vcs.removed },
    DiffText = { fg = p.syntax.operator },
    GitSignsAdd = { fg = p.vcs.added },
    GitSignsChange = { fg = p.vcs.modified },
    GitSignsDelete = { fg = p.vcs.removed },
  }
end

return M
