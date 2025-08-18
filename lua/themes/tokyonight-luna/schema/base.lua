local api = vim.api
local blend_bg = require("themes.util").blend_bg
local blend_fg = require("themes.util").blend_fg
local M = {}

M.get = function(c, t)
  local s = {
    Comment                     = { fg = c.comment },                              -- any comment
    ColorColumn                 = { bg = c.black },                                -- used for the columns set with 'colorcolumn'
    Conceal                     = { fg = c.dark5 },                                -- placeholder characters substituted for concealed text (see 'conceallevel')
    Cursor                      = { fg = c.bg, bg = c.fg },                        -- character under the cursor
    lCursor                     = { fg = c.bg, bg = c.fg },                        -- the character under the cursor when |language-mapping| is used (see 'guicursor')
    CursorIM                    = { fg = c.bg, bg = c.fg },                        -- like Cursor, but used when in IME mode |CursorIM|
    CursorColumn                = { bg = c.bg_dark2 },                             -- Screen-column at the cursor, when 'cursorcolumn' is set.
    CursorLine                  = { bg = c.bg_dark2 },                             -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if foreground (ctermfg OR guifg) is not set.
    Directory                   = { fg = c.blue },                                 -- directory names (and other special names in listings)
    DiffAdd                     = { bg = blend_bg(c.green2, 0.15, c.bg) },         -- diff mode: Added line |diff.txt|
    DiffChange                  = { bg = blend_bg(c.blue7, 0.15, c.bg) },          -- diff mode: Changed line |diff.txt|
    DiffDelete                  = { bg = blend_bg(c.red1, 0.15, c.bg) },           -- diff mode: Deleted line |diff.txt|
    DiffText                    = { bg = c.blue7 },                                -- diff mode: Changed text within a changed line |diff.txt|
    EndOfBuffer                 = { fg = c.bg },                                   -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
    ErrorMsg                    = { fg = c.red },                                  -- error messages on the command line
    VertSplit                   = { fg = c.black },                                -- the column separating vertically split windows
    WinSeparator                = { fg = c.border_highlight, bold = true },        -- the column separating vertically split windows
    Folded                      = { fg = c.blue, bg = c.fg_gutter },               -- line used for closed folds
    FoldColumn                  = { bg = t and c.none or c.bg, fg = c.comment },   -- 'foldcolumn'
    SignColumn                  = { bg = t and c.none or c.bg, fg = c.fg_gutter }, -- column where |signs| are displayed
    SignColumnSB                = { bg = c.bg_dark, fg = c.fg_gutter },            -- column where |signs| are displayed
    Substitute                  = { bg = c.red, fg = c.black },                    -- |:substitute| replacement text highlighting
    LineNr                      = { fg = c.fg_gutter },                            -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
    CursorLineNr                = { fg = c.orange, bold = true },                  -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
    LineNrAbove                 = { fg = c.fg_gutter },
    LineNrBelow                 = { fg = c.fg_gutter },
    MatchParen                  = { fg = c.orange, bold = true },           -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
    ModeMsg                     = { fg = c.fg_dark, bold = true },          -- 'showmode' message (e.g., "-- INSERT -- ")
    MsgArea                     = { fg = c.fg_dark },                       -- Area for messages and cmdline
    MoreMsg                     = { fg = c.blue },                          -- |more-prompt|
    NonText                     = { fg = c.dark3 },                         -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
    Normal                      = { fg = c.fg, bg = t and c.none or c.bg }, -- normal text
    NormalNC                    = { fg = c.fg, bg = t and c.none or c.bg }, -- normal text in non-current windows
    NormalSB                    = { fg = c.fg_dark, bg = c.bg_dark },       -- normal text in sidebar
    NormalFloat                 = { fg = c.fg, bg = c.bg_dark },            -- Normal text in floating windows.
    FloatBorder                 = { fg = c.border_highlight, bg = c.bg_dark },
    FloatTitle                  = { link = "FloatBorder" },
    Pmenu                       = { bg = c.bg_dark, fg = c.fg },                     -- Popup menu: normal item.
    PmenuMatch                  = { bg = c.bg_dark, fg = c.blue1 },                  -- Popup menu: Matched text in normal item.
    PmenuSel                    = { bg = blend_bg(c.fg_gutter, 0.8, c.bg) },         -- Popup menu: selected item.
    PmenuMatchSel               = { bg = blend_bg(c.fg_gutter, 0.8), fg = c.blue1 }, -- Popup menu: Matched text in selected item.
    PmenuSbar                   = { bg = blend_fg(c.bg_dark, 0.95, c.fg) },          -- Popup menu: scrollbar.
    PmenuThumb                  = { bg = c.fg_gutter },                              -- Popup menu: Thumb of the scrollbar.
    Question                    = { fg = c.blue },                                   -- |hit-enter| prompt and yes/no questions
    QuickFixLine                = { bg = c.bg_visual, bold = true },                 -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    Search                      = { bg = c.blue0, fg = c.fg },                       -- Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
    IncSearch                   = { bg = c.orange, fg = c.black },                   -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
    CurSearch                   = { link = "IncSearch" },
    SpecialKey                  = { fg = c.dark3 },                                  -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' whitespace. |hl-Whitespace|
    SpellBad                    = { sp = c.red, undercurl = true },                  -- Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.
    SpellCap                    = { sp = c.yellow, undercurl = true },               -- Word that should start with a capital. |spell| Combined with the highlighting used otherwise.
    SpellLocal                  = { sp = c.blue2, undercurl = true },                -- Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.
    SpellRare                   = { sp = c.teal, undercurl = true },                 -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.
    StatusLine                  = { fg = c.fg_dark, bg = c.dark },                   -- status line of current window
    StatusLineNC                = { fg = c.fg_gutter, bg = c.dark },                 -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
    TabLine                     = { bg = c.dark, fg = c.fg_gutter },                 -- tab pages line, not active tab page label
    TabLineFill                 = { bg = c.black },                                  -- tab pages line, where there are no labels
    TabLineSel                  = { fg = c.black, bg = c.blue },                     -- tab pages line, active tab page label
    Title                       = { fg = c.blue, bold = true },                      -- titles for output from ":set all", ":autocmd" etc.
    Visual                      = { bg = c.bg_visual },                              -- Visual mode selection
    VisualNOS                   = { bg = c.bg_visual },                              -- Visual mode selection when vim is "Not Owning the Selection".
    WarningMsg                  = { fg = c.yellow },                                 -- warning messages
    Whitespace                  = { fg = c.fg_gutter },                              -- "nbsp", "space", "tab" and "trail" in 'listchars'
    WildMenu                    = { bg = c.bg_visual },                              -- current match in 'wildmenu' completion
    WinBar                      = { link = "StatusLine" },                           -- window bar
    WinBarNC                    = { link = "StatusLineNC" },                         -- window bar in inactive windows

    Bold                        = { bold = true, fg = c.fg },                        -- (preferred) any bold text
    Character                   = { fg = c.green },                                  --  a character constant: 'c', '\n'
    Constant                    = { fg = c.orange },                                 -- (preferred) any constant
    Debug                       = { fg = c.orange },                                 --    debugging statements
    Delimiter                   = { link = "Special" },                              --  character that needs attention
    Error                       = { fg = c.red },                                    -- (preferred) any erroneous construct
    Function                    = { fg = c.blue },                                   -- function name (also: methods for classes)
    Identifier                  = { fg = c.magenta },                                -- (preferred) any variable name
    Italic                      = { italic = true, fg = c.fg },                      -- (preferred) any italic text
    Keyword                     = { fg = c.cyan },                                   --  any other keyword
    Operator                    = { fg = c.blue5 },                                  -- "sizeof", "+", "*", etc.
    PreProc                     = { fg = c.cyan },                                   -- (preferred) generic Preprocessor
    Special                     = { fg = c.blue1 },                                  -- (preferred) any special symbol
    Statement                   = { fg = c.magenta },                                -- (preferred) any statement
    String                      = { fg = c.green },                                  --   a string constant: "this is a string"
    Todo                        = { bg = c.yellow, fg = c.bg },                      -- (preferred) anything that needs extra attention; mostly the keywords TODO FIXME and XXX
    Type                        = { fg = c.blue1 },                                  -- (preferred) int, long, char, etc.
    Underlined                  = { underline = true },                              -- (preferred) text that stands out, HTML links

    LspReferenceText            = { bg = c.fg_gutter }, -- used for highlighting "text" references
    LspReferenceRead            = { bg = c.fg_gutter }, -- used for highlighting "read" references
    LspReferenceWrite           = { bg = c.fg_gutter }, -- used for highlighting "write" references
    LspSignatureActiveParameter = { bg = blend_bg(c.bg_visual, 0.4, c.bg), bold = true },
    LspCodeLens                 = { fg = c.comment },
    LspInlayHint                = { bg = blend_bg(c.blue7, 0.1, c.bg), fg = c.dark3 },
    LspInfoBorder               = { fg = c.border_highlight, bg = c.bg_dark },

    DiagnosticError             = { fg = c.red },                                        -- Used as the base highlight group. Other Diagnostic highlights link to this by default
    DiagnosticWarn              = { fg = c.yellow },                                     -- Used as the base highlight group. Other Diagnostic highlights link to this by default
    DiagnosticInfo              = { fg = c.blue2 },                                      -- Used as the base highlight group. Other Diagnostic highlights link to this by default
    DiagnosticHint              = { fg = c.teal },                                       -- Used as the base highlight group. Other Diagnostic highlights link to this by default
    DiagnosticUnnecessary       = { fg = c.bg_dark3 },                                   -- Used as the base highlight group. Other Diagnostic highlights link to this by default
    DiagnosticVirtualTextError  = { bg = blend_bg(c.red, 0.1, c.bg), fg = c.red },       -- Used for "Error" diagnostic virtual text
    DiagnosticVirtualTextWarn   = { bg = blend_bg(c.yellow, 0.1, c.bg), fg = c.yellow }, -- Used for "Warning" diagnostic virtual text
    DiagnosticVirtualTextInfo   = { bg = blend_bg(c.blue2, 0.1, c.bg), fg = c.blue2 },   -- Used for "Information" diagnostic virtual text
    DiagnosticVirtualTextHint   = { bg = blend_bg(c.teal, 0.1, c.bg), fg = c.teal },     -- Used for "Hint" diagnostic virtual text
    DiagnosticUnderlineError    = { undercurl = true, sp = c.red },                      -- Used to underline "Error" diagnostics
    DiagnosticUnderlineWarn     = { undercurl = true, sp = c.yellow },                   -- Used to underline "Warning" diagnostics
    DiagnosticUnderlineInfo     = { undercurl = true, sp = c.blue2 },                    -- Used to underline "Information" diagnostics
    DiagnosticUnderlineHint     = { undercurl = true, sp = c.teal },                     -- Used to underline "Hint" diagnostics
  }

  ---@format disable-next
  local hl = api.nvim_set_hl
  for key, val in pairs(s) do hl(0, key, val) end
end

return M
