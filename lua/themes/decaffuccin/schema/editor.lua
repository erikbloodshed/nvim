local M = {}

function M.get(c, o)
  return {
    ColorColumn           = { bg = c.surface0 },                                                                        -- used for the columns set with 'colorcolumn'
    Conceal               = { fg = c.overlay1 },                                                                        -- placeholder characters substituted for concealed text (see 'conceallevel')
    Cursor                = { fg = c.base, bg = c.rosewater },                                                          -- character under the cursor
    lCursor               = { link = "Cursor" },                                                                        -- the character under the cursor when |language-mapping| is used (see 'guicursor')
    CursorIM              = { link = "Cursor" },                                                                        -- like Cursor, but used when in IME mode |CursorIM|
    CursorColumn          = { bg = c.mantle },                                                                          -- Screen-column at the cursor, when 'cursorcolumn' is set.
    CursorLine            = { bg = c.bg_line },                                                                         -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if forecrust (ctermfg OR guifg) is not set.
    Directory             = { fg = c.blue },                                                                            -- directory names (and other special names in listings)
    EndOfBuffer           = { fg = c.base, },                                                                           -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
    ErrorMsg              = { fg = c.red, bold = true, italic = true },                                                 -- error messages on the command line
    VertSplit             = { fg = o.transparency and c.surface1 or c.crust },                                          -- the column separating vertically split windows
    Folded                = { fg = c.blue, bg = o.transparency and c.none or c.surface1 },                              -- line used for closed folds
    FoldColumn            = { fg = c.overlay0 },                                                                        -- 'foldcolumn'
    SignColumn            = { fg = c.surface1 },                                                                        -- column where |signs| are displayed
    SignColumnSB          = { bg = c.crust, fg = c.surface1 },                                                          -- column where |signs| are displayed
    Substitute            = { bg = c.surface1, fg = c.pink },                                                           -- |:substitute| replacement text highlighting
    LineNr                = { fg = c.surface1 },                                                                        -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
    CursorLineNr          = { fg = c.lavender },                                                                        -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line. highlights the number in numberline.
    MatchParen            = { fg = c.peach, bg = c.surface1, bold = true },                                             -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
    ModeMsg               = { fg = c.text, bold = true },                                                               -- 'showmode' message (e.g., "-- INSERT -- ")
    MsgSeparator          = {},                                                                                         -- Separator for scrolled messages, `msgsep` flag of 'display'
    MoreMsg               = { fg = c.blue },                                                                            -- |more-prompt|
    NonText               = { fg = c.overlay0 },                                                                        -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
    Normal                = { fg = c.text, bg = o.transparency and c.none or c.base },                                  -- normal text
    NormalNC              = { fg = c.text, bg = o.transparency and c.none or c.dim, },                                  -- normal text in non-current windows
    NormalSB              = { fg = c.text, bg = c.crust },                                                              -- normal text in non-current windows
    NormalFloat           = { fg = c.text, bg = (o.float.transparent and vim.o.winblend == 0) and c.none or c.mantle }, -- Normal text in floating windows.
    FloatBorder           = { fg = c.surface1, bg = c.mantle },
    FloatTitle            = o.float.solid and {
      fg = c.crust,
      bg = c.lavender,
    } or { fg = c.subtext0, bg = (o.float.transparent and vim.o.winblend == 0) and c.none or c.mantle },
    FloatShadow           = { fg = (o.float.transparent and vim.o.winblend == 0) and c.none or c.overlay0 },

    Pmenu                 = {
      bg = (o.transparency and vim.o.pumblend == 0) and c.none or c.mantle,
      fg = c.overlay2,
    },                                                                                       -- Popup menu: normal item.
    PmenuSel              = { bg = c.surface0, bold = true },                                -- Popup menu: selected item.
    PmenuSbar             = { bg = c.surface0 },                                             -- Popup menu: scrollbar.
    PmenuThumb            = { bg = c.overlay0 },                                             -- Popup menu: Thumb of the scrollbar.
    PmenuExtra            = { fg = c.overlay0 },                                             -- Popup menu: normal item extra text.
    PmenuExtraSel         = { fg = c.overlay0, bold = true },                                -- Popup menu: selected item extra text.
    Question              = { fg = c.blue },                                                 -- |hit-enter| prompt and yes/no questions
    QuickFixLine          = { bg = c.surface1, bold = true },                                -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
    Search                = { bg = c.bg_search, fg = c.text },                               -- Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
    IncSearch             = { bg = c.bg_incsearch, fg = c.mantle },                          -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
    CurSearch             = { bg = c.red, fg = c.mantle },                                   -- 'cursearch' highlighting: highlights the current search you're on differently
    SpecialKey            = { link = "NonText" },                                            -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' textspace. |hl-Whitespace|
    SpellBad              = { sp = c.red, undercurl = true },                                -- Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.
    SpellCap              = { sp = c.yellow, undercurl = true },                             -- Word that should start with a capital. |spell| Combined with the highlighting used otherwise.
    SpellLocal            = { sp = c.blue, undercurl = true },                               -- Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.
    SpellRare             = { sp = c.green, undercurl = true },                              -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.
    StatusLine            = { fg = c.text, bg = o.transparency and c.none or c.mantle },     -- status line of current window
    StatusLineNC          = { fg = c.surface1, bg = o.transparency and c.none or c.mantle }, -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.

    StatusLineNormal      = { bg = c.blue, fg = c.crust },
    StatusLineInsert      = { bg = c.green, fg = c.crust },
    StatusLineVisual      = { bg = c.mauve, fg = c.crust },
    StatusLineCommand     = { bg = c.yellow, fg = c.crust },
    StatusLineReplace     = { bg = c.maroon, fg = c.crust },
    StatusLineTerminal    = { bg = c.green, fg = c.crust },
    StatusLineGit         = { fg = c.peach },
    StatusLineModified    = { fg = c.yellow },
    StatusLineFile        = { fg = c.text },
    StatusLineDiagError   = { link = "DiagnosticError" },
    StatusLineDiagWarning = { link = "DiagnosticWarn" },
    StatusLineDiagHint    = { link = "DiagnosticHint" },
    StatusLineDiagInfo    = { link = "DiagnosticInfo" },
    StatusLineLsp         = { fg = c.green },
    StatusLineLabel       = { fg = c.surface1 },
    StatusLineValue       = { fg = c.peach },
    StatusLineSeparator   = { fg = c.surface0 },

    TabLine               = { bg = c.crust, fg = c.overlay0 },              -- tab pages line, not active tab page label
    TabLineFill           = { bg = o.transparency and c.none or c.mantle }, -- tab pages line, where there are no labels
    TabLineSel            = { link = "Normal" },                            -- tab pages line, active tab page label
    TermCursor            = { fg = c.base, bg = c.rosewater },              -- cursor in a focused terminal
    TermCursorNC          = { fg = c.base, bg = c.overlay2 },               -- cursor in unfocused terminals
    Title                 = { fg = c.blue, bold = true },                   -- titles for output from ":set all", ":autocmd" etc.
    Visual                = { bg = c.surface1, bold = true },               -- Visual mode selection
    VisualNOS             = { link = "Visual" },                            -- Visual mode selection when vim is "Not Owning the Selection".
    WarningMsg            = { fg = c.yellow },                              -- warning messages
    Whitespace            = { fg = c.surface1 },                            -- "nbsp", "space", "tab" and "trail" in 'listchars'
    WildMenu              = { bg = c.overlay0 },                            -- current match in 'wildmenu' completion
    WinBar                = { fg = c.rosewater },
    WinBarNC              = { link = "WinBar" },
    WinSeparator          = { fg = o.transparency and c.surface1 or c.crust },
  }
end

return M
