local M = {}

M.get = function(c)
  return {
    -- {{{ statusline
    StatusLineNormal            = { bg = c.blue, fg = c.black },
    StatusLineInsert            = { bg = c.green, fg = c.black },
    StatusLineVisual            = { bg = c.magenta, fg = c.black },
    StatusLineCommand           = { bg = c.yellow, fg = c.black },
    StatusLineReplace           = { bg = c.red, fg = c.black },
    StatusLineTerminal          = { bg = c.green1, fg = c.black },
    StatusLineGit               = { fg = c.orange },
    StatusLineModified          = { fg = c.yellow },
    StatusLineFile              = { fg = c.fg_dark },
    StatusLineDiagError         = { link = "DiagnosticError" },
    StatusLineDiagWarning       = { link = "DiagnosticWarn" },
    StatusLineDiagHint          = { link = "DiagnosticHint" },
    StatusLineDiagInfo          = { link = "DiagnosticInfo" },
    StatusLineLsp               = { fg = c.green },
    StatusLineLabel             = { fg = c.fg_dark },
    StatusLineValue             = { fg = c.orange },
    StatusLineSeparator         = { fg = c.bg_dark2 }, -- }}}
    -- {{{ 🌈 Text Styles
    Bold                        = { bold = true, fg = c.fg },
    Italic                      = { italic = true, fg = c.fg },
    Underlined                  = { underline = true }, -- }}}
    -- {{{ 📑 UI / Editor Elements
    ColorColumn                 = { bg = c.black },
    Conceal                     = { fg = c.dark5 },
    Cursor                      = { fg = c.bg, bg = c.fg },
    CursorIM                    = { fg = c.bg, bg = c.fg },
    CursorLine                  = { bg = c.bg_dark2 },
    CursorColumn                = { link = "CursorLine" },
    CursorLineNr                = { fg = c.orange, bold = true },
    EndOfBuffer                 = { fg = c.bg },
    LineNr                      = { fg = c.fg_gutter, bg = c.background },
    LineNrAbove                 = { link = "LineNr" },
    LineNrBelow                 = { link = "LineNr" },
    MatchParen                  = { fg = c.orange, bold = true },
    NonText                     = { fg = c.fg_gutter, nocombine = true },
    Normal                      = { fg = c.fg, bg = c.background },
    NormalNC                    = { fg = c.fg, bg = c.background },
    NormalSB                    = { fg = c.fg_dark, bg = c.bg_dark },
    NormalFloat                 = { fg = c.fg, bg = c.bg_dark },
    Pmenu                       = { bg = c.bg_dark, fg = c.fg },
    PmenuSel                    = { bg = c.bg_selection },
    PmenuMatch                  = { bg = c.bg_dark, fg = c.blue1 },
    PmenuMatchSel               = { bg = c.bg_selection, fg = c.blue1 },
    PmenuSbar                   = { bg = c.bg_sbar },
    PmenuThumb                  = { bg = c.fg_gutter },
    SignColumn                  = { bg = c.background, fg = c.fg_gutter },
    SignColumnSB                = { bg = c.bg_dark, fg = c.fg_gutter },
    TabLine                     = { bg = c.dark, fg = c.fg_gutter },
    TabLineFill                 = { bg = c.black },
    TabLineSel                  = { fg = c.black, bg = c.blue },
    Title                       = { fg = c.blue, bold = true },
    Visual                      = { bg = c.blue8 },
    VisualNOS                   = { link = "Visual" },
    Whitespace                  = { fg = c.fg_gutter, nocombine = true },
    WinBar                      = { link = "StatusLine" },
    WinBarNC                    = { link = "StatusLineNC" },
    WinSeparator                = { fg = c.fg_gutter },
    lCursor                     = { link = "Cursor" }, -- }}}
    -- {{{ 🖼 Floating Windows
    FloatBorder                 = { fg = c.fg_border, bg = c.bg_dark },
    FloatTitle                  = { link = "FloatBorder" }, -- }}}
    -- {{{ 📜 Status & Messages
    ModeMsg                     = { fg = c.fg_dark, bold = true },
    MoreMsg                     = { fg = c.blue },
    MsgArea                     = { fg = c.fg_dark },
    Question                    = { fg = c.blue },
    QuickFixLine                = { bg = c.blue8, bold = true },
    StatusLine                  = { fg = c.fg_dark, bg = c.dark },
    StatusLineNC                = { fg = c.fg_gutter, bg = c.dark },
    WarningMsg                  = { fg = c.yellow },
    WildMenu                    = { link = "Visual" },
    ErrorMsg                    = { fg = c.red }, -- }}}
    -- {{{🔍 Search & Highlight
    CurSearch                   = { link = "IncSearch" },
    IncSearch                   = { bg = c.orange, fg = c.black },
    Search                      = { bg = c.blue0, fg = c.fg },
    Substitute                  = { bg = c.red, fg = c.black }, -- }}}
    -- {{{ 🧾 Folding
    FoldColumn                  = { bg = c.background, fg = c.fg_comment },
    Folded                      = { fg = c.blue, bg = c.fg_gutter }, -- }}}
    -- {{{ 🔔 Diagnostics
    DiagnosticError             = { fg = c.red },
    DiagnosticWarn              = { fg = c.yellow },
    DiagnosticInfo              = { fg = c.blue2 },
    DiagnosticHint              = { fg = c.teal },
    DiagnosticUnnecessary       = { fg = c.bg_dark3 },
    DiagnosticUnderlineError    = { undercurl = true, sp = c.red },
    DiagnosticUnderlineWarn     = { undercurl = true, sp = c.yellow },
    DiagnosticUnderlineInfo     = { undercurl = true, sp = c.blue2 },
    DiagnosticUnderlineHint     = { undercurl = true, sp = c.teal },
    DiagnosticVirtualTextError  = { bg = c.bg_error, fg = c.red },
    DiagnosticVirtualTextWarn   = { bg = c.bg_warn, fg = c.yellow },
    DiagnosticVirtualTextInfo   = { bg = c.bg_info, fg = c.blue2 },
    DiagnosticVirtualTextHint   = { bg = c.bg_hint, fg = c.teal }, -- }}}
    -- {{{ 🔧 LSP
    LspCodeLens                 = { fg = c.fg_comment },
    LspInfoBorder               = { fg = c.fg_border, bg = c.bg_dark },
    LspInlayHint                = { fg = c.dark3, bg = c.bg_dark4 },
    LspReferenceRead            = { bg = c.fg_gutter },
    LspReferenceText            = { bg = c.fg_gutter },
    LspReferenceWrite           = { bg = c.fg_gutter },
    LspSignatureActiveParameter = { bg = c.bg_param, bold = true }, -- }}}
    -- {{{ 🔀 Diff
    DiffAdd                     = { bg = c.bg_add },
    DiffChange                  = { bg = c.bg_change },
    DiffDelete                  = { bg = c.bg_delete },
    DiffText                    = { bg = c.bg_text }, -- }}}
    -- {{{ 🔑 Special Keys
    Directory                   = { fg = c.blue },
    SpecialKey                  = { fg = c.dark3 }, -- }}}
    -- {{{ 🧩 Misc
    Error                       = { fg = c.red },
    Todo                        = { bg = c.yellow, fg = c.bg }, -- }}}
  }
end

return M
