-- Base editor highlights for Nord theme
local M = {}

function M.get_highlights(palette)
  return {
    -- Status line highlights
    StatusLineNormal = { fg = palette.magenta.bright, bold = true, reverse = true },
    StatusLineInsert = { fg = palette.green.bright, bold = true, reverse = true },
    StatusLineVisual = { fg = palette.blue1, bold = true, reverse = true },
    StatusLineCommand = { fg = palette.yellow.bright, bold = true, reverse = true },
    StatusLineReplace = { fg = palette.red.bright, bold = true, reverse = true },
    StatusLineTerminal = { fg = palette.blue2, bold = true, reverse = true },
    StatusLineFile = { fg = palette.white0_normal, bold = true },
    StatusLineModified = { fg = palette.yellow.base, bold = true },
    StatusLineReadonly = { fg = palette.gray5 },
    StatusLineGit = { fg = palette.orange.base },
    StatusLineInfo = { fg = palette.gray5 },
    StatusLineLabel = { fg = palette.gray5 },
    StatusLineValue = { fg = palette.magenta.base },
    StatusLineDiagError = { fg = palette.red.bright },
    StatusLineDiagWarn = { fg = palette.yellow.base },
    StatusLineDiagInfo = { fg = palette.blue2 },
    StatusLineDiagHint = { fg = palette.green.dim },
    StatusLineLSP = { fg = palette.green.base },
    StatusLine = { fg = palette.white0_normal, bg = palette.black2 },
    StatusLineNC = { fg = palette.gray5, bg = palette.none },

    -- Core editor UI
    ColorColumn = { bg = palette.gray3 },
    Cursor = { fg = palette.blue2, bg = palette.white0_normal },
    CursorColumn = { bg = palette.gray1 },
    CursorLine = { bg = palette.gray1 },
    CursorLineNr = { fg = palette.white1, bg = palette.gray1 },
    Directory = { fg = palette.magenta.base, bold = true },
    EndOfBuffer = { fg = palette.black1 },
    ErrorMsg = { fg = palette.red.bright },
    FloatBorder = { fg = palette.blue1, bg = palette.none },
    FoldColumn = { fg = palette.gray5, bg = palette.gray1 },
    Folded = { fg = palette.gray5, bg = palette.gray3 },
    IncSearch = { fg = palette.gray1, bg = palette.orange.base },
    LineNr = { fg = palette.gray5 }, -- Changed for WCAG compliance (4.8:1)
    MatchParen = { fg = palette.black1, bg = palette.white0_reduce_blue, bold = true },
    ModeMsg = { fg = palette.white0_normal },
    MoreMsg = { fg = palette.green.base },
    NonText = { fg = palette.gray5 },
    Normal = { fg = palette.white0_normal, bg = palette.none },
    NormalFloat = { link = "Normal" }, -- Darker bg for popups

    -- Popup menu
    Pmenu = { fg = palette.white0_normal, bg = palette.black0 },
    PmenuSbar = { bg = palette.gray3 },
    PmenuSel = { fg = palette.gray0, bg = palette.blue1 },
    PmenuThumb = { bg = palette.gray5 },

    -- Search and selection
    Question = { fg = palette.green.base },
    QuickFixLine = { fg = palette.gray1, bg = palette.yellow.base },
    Search = { fg = palette.gray1, bg = palette.yellow.base },
    SignColumn = { fg = palette.gray5, bg = palette.none },
    SpecialKey = { fg = palette.gray5 },

    -- Tabs
    TabLine = { fg = palette.gray5, bg = palette.gray1 },
    TabLineFill = { bg = palette.gray1 },
    TabLineSel = { fg = palette.white0_normal, bg = palette.gray3 },

    -- Miscellaneous
    Title = { fg = palette.blue1, bold = true },
    VertSplit = { fg = palette.gray3 },
    Visual = { bg = palette.gray3 },
    VisualNOS = { bg = palette.gray3 },
    WarningMsg = { fg = palette.yellow.base },
    Whitespace = { fg = palette.gray5 },
    WildMenu = { fg = palette.gray1, bg = palette.magenta.base },
    WinSeparator = { fg = palette.gray3 },

    -- Diagnostic highlights
    DiagnosticError = { fg = palette.red.bright },
    DiagnosticWarn = { fg = palette.yellow.base },
    DiagnosticInfo = { fg = palette.blue2 },
    DiagnosticHint = { fg = palette.green.dim }, -- Changed for WCAG compliance (5.84:1)
    DiagnosticUnderlineError = { undercurl = true, sp = palette.red.bright },
    DiagnosticUnderlineWarn = { undercurl = true, sp = palette.yellow.base },
    DiagnosticUnderlineInfo = { undercurl = true, sp = palette.blue2 },
    DiagnosticUnderlineHint = { undercurl = true, sp = palette.green.dim },

    -- Git/Diff highlights
    DiffAdd = { fg = palette.green.base },
    DiffChange = { fg = palette.yellow.base },
    DiffDelete = { fg = palette.red.bright },
    DiffText = { fg = palette.orange.base },
    GitSignsAdd = { fg = palette.green.base },
    GitSignsChange = { fg = palette.yellow.base },
    GitSignsDelete = { fg = palette.red.bright },
  }
end

return M
