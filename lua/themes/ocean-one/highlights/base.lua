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
    StatusLineDiagWarn = { fg = p.syntax.func },
    StatusLineDiagInfo = { fg = p.syntax.entity },
    StatusLineDiagHint = { fg = p.syntax.tag },
    StatusLineLSP = { fg = p.syntax.string },
    StatusLine = { fg = p.editor.fg, bg = p.ui.bg },
    StatusLineNC = { fg = p.ui.fg, bg = p.ui.bg },

    -- Core editor UI
    ColorColumn = { bg = p.editor.line },
    Cursor = { fg = p.editor.bg, bg = p.editor.fg },
    CursorColumn = { bg = p.editor.line },
    CursorLine = { bg = p.editor.line },
    CursorLineNr = { link = "CursorLine"},
    Directory = { fg = p.syntax.func, bold = true },
    EndOfBuffer = { fg = p.editor.bg },
    ErrorMsg = { fg = p.common.error },
    FloatBorder = { fg = p.ui.line, bg = p.ui.bg },
    FloatTitle = { fg = p.syntax.keyword, bg = p.ui.bg, bold = true },
    FoldColumn = { fg = p.ui.fg, bg = p.ui.bg },
    Folded = { fg = p.ui.fg, bg = p.ui.bg },
    IncSearch = { fg = p.editor.bg, bg = p.syntax.operator },
    LineNr = { fg = p.ui.line },
    MatchParen = { fg = p.editor.line, bg = p.syntax.comment, bold = true },
    ModeMsg = { fg = p.editor.fg },
    MoreMsg = { fg = p.syntax.string },
    NonText = { fg = p.syntax.comment },
    Normal = { fg = p.editor.fg, bg = p.editor.bg },
    NormalFloat = { fg = p.ui.fg, bg = p.ui.bg },
    NormalNC = { link = "Normal" },

    -- Popup menu
    Pmenu = { fg = p.ui.fg, bg = p.ui.bg },
    PmenuSbar = { bg = p.ui.bg },
    PmenuSel = { fg = p.editor.bg, bg = p.syntax.entity },
    PmenuThumb = { bg = p.ui.line },

    -- Search and selection
    Question = { fg = p.syntax.string },
    QuickFixLine = { fg = p.editor.bg, bg = p.syntax.func },
    Search = { fg = p.editor.bg, bg = p.syntax.func },
    SignColumn = { fg = p.syntax.comment, bg = p.editor.bg },
    SpecialKey = { fg = p.syntax.comment },
    SpellBad = { fg = p.common.error, undercurl = true, sp = p.common.error },
    SpellCap = { fg = p.syntax.special, undercurl = true, sp = p.syntax.special },
    SpellLocal = { fg = p.syntax.tag, undercurl = true, sp = p.syntax.tag },
    SpellRare = { fg = p.syntax.entity, undercurl = true, sp = p.syntax.entity },

    -- Tabs
    TabLine = { fg = p.ui.fg, bg = p.editor.bg },
    TabLineFill = { bg = p.ui.bg },
    TabLineSel = { fg = p.ui.bg, bg = p.syntax.keyword},

    -- Miscellaneous
    Title = { fg = p.syntax.keyword, bold = true },
    VertSplit = { fg = p.ui.line },
    Visual = { bg = p.editor.selection.active },
    VisualNOS = { bg = p.editor.selection.inactive },
    WarningMsg = { fg = p.syntax.special },
    Whitespace = { fg = p.syntax.comment },
    WildMenu = { fg = p.editor.bg, bg = p.syntax.constant },
    WinSeparator = { fg = p.ui.line },

    -- LSP Reference highlighting
    LspReferenceRead = { bg = p.editor.selection.inactive },
    LspReferenceWrite = { bg = p.editor.selection.inactive, bold = true },
    LspReferenceText = { bg = p.editor.selection.inactive },

    -- LSP Signature help
    LspSignatureActiveParameter = { fg = p.syntax.operator, bold = true },

    -- LSP Code lens
    LspCodeLens = { fg = p.syntax.comment, italic = true },
    LspCodeLensSeparator = { fg = p.syntax.comment },

    -- Diagnostic highlights
    DiagnosticError = { fg = p.common.error },
    DiagnosticWarn = { fg = p.syntax.special },
    DiagnosticInfo = { fg = p.syntax.entity },
    DiagnosticHint = { fg = p.syntax.tag },
    DiagnosticOk = { fg = p.vcs.added },
    DiagnosticUnderlineError = { undercurl = true, sp = p.common.error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = p.syntax.special },
    DiagnosticUnderlineInfo = { undercurl = true, sp = p.syntax.entity },
    DiagnosticUnderlineHint = { undercurl = true, sp = p.syntax.tag },
    DiagnosticUnderlineOk = { undercurl = true, sp = p.vcs.added },
    DiagnosticVirtualTextError = { fg = p.common.error, bg = p.editor.line },
    DiagnosticVirtualTextWarn = { fg = p.syntax.special, bg = p.editor.line },
    DiagnosticVirtualTextInfo = { fg = p.syntax.entity, bg = p.editor.line },
    DiagnosticVirtualTextHint = { fg = p.syntax.tag, bg = p.editor.line },
    DiagnosticVirtualTextOk = { fg = p.vcs.added, bg = p.editor.line },
    DiagnosticFloatingError = { fg = p.common.error },
    DiagnosticFloatingWarn = { fg = p.syntax.special },
    DiagnosticFloatingInfo = { fg = p.syntax.entity },
    DiagnosticFloatingHint = { fg = p.syntax.tag },
    DiagnosticFloatingOk = { fg = p.vcs.added },
    DiagnosticSignError = { fg = p.common.error, bg = p.editor.bg },
    DiagnosticSignWarn = { fg = p.syntax.special, bg = p.editor.bg },
    DiagnosticSignInfo = { fg = p.syntax.entity, bg = p.editor.bg },
    DiagnosticSignHint = { fg = p.syntax.tag, bg = p.editor.bg },
    DiagnosticSignOk = { fg = p.vcs.added, bg = p.editor.bg },

    DiffAdd = { fg = p.vcs.added },
    DiffChange = { fg = p.vcs.modified },
    DiffDelete = { fg = p.vcs.removed },
    DiffText = { fg = p.syntax.operator },
    GitSignsAdd = { fg = p.vcs.added },
    GitSignsChange = { fg = p.vcs.modified },
    GitSignsDelete = { fg = p.vcs.removed },

    Terminal0 = { fg = p.terminal.black },
    Terminal1 = { fg = p.terminal.red },
    Terminal2 = { fg = p.terminal.green },
    Terminal3 = { fg = p.terminal.yellow },
    Terminal4 = { fg = p.terminal.blue },
    Terminal5 = { fg = p.terminal.magenta },
    Terminal6 = { fg = p.terminal.cyan },
    Terminal7 = { fg = p.terminal.white },
    Terminal8 = { fg = p.terminal.bright_black },
    Terminal9 = { fg = p.terminal.bright_red },
    Terminal10 = { fg = p.terminal.bright_green },
    Terminal11 = { fg = p.terminal.bright_yellow },
    Terminal12 = { fg = p.terminal.bright_blue },
    Terminal13 = { fg = p.terminal.bright_magenta },
    Terminal14 = { fg = p.terminal.bright_cyan },
    Terminal15 = { fg = p.terminal.bright_white },
  }
end

return M
