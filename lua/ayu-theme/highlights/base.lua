-- Base editor highlights for Nord theme
local M = {}

function M.get_highlights(p)
  return {
    ColorColumn = { fg = nil, bg = p.editor.bg },                                        -- Columns set with 'colorcolumn'.
    Conceal = { fg = p.syntax.comment, bg = p.editor.bg },                                 -- Placeholder characters for concealed text.
    CurSearch = { fg = p.editor.bg, bg = p.common.accent },                                -- Current match for the last search pattern.
    Cursor = { fg = p.editor.bg, bg = p.common.accent },                                   -- Character under the cursor.
    lCursor = { fg = p.editor.bg, bg = p.common.accent },                                  -- Character under the cursor when language-mapping is used.
    CursorIM = { fg = p.editor.bg, bg = p.common.accent },                                 -- Like Cursor, but used in IME mode.
    CursorColumn = { fg = nil, bg = p.editor.line },                                     -- Screen-column at the cursor when 'cursorcolumn' is set.
    CursorLine = { fg = nil, bg = p.editor.line },                                       -- Screen-line at the cursor when 'cursorline' is set.
    Directory = { fg = p.syntax.tag, bg = nil },                                         -- Directory names and special names in listings.
    DiffAdd = { fg = nil, bg = p.vcs.added },                                            -- Diff mode: Added line.
    DiffChange = { fg = nil, bg = p.vcs.modified },                                      -- Diff mode: Changed line.
    DiffDelete = { fg = nil, bg = p.vcs.removed },                                       -- Diff mode: Deleted line.
    DiffText = { fg = p.editor.bg, bg = p.syntax.func },                                   -- Diff mode: Changed text within a changed line.
    DiffTextAdd = { fg = p.editor.bg, bg = p.vcs.added },                                  -- Added text within a changed line.
    EndOfBuffer = { fg = p.ui.fg, bg = nil },                                            -- Filler lines (~) after the last line in the buffer.
    TermCursor = { fg = p.editor.bg, bg = p.common.accent },                               -- Cursor in a focused terminal.
    ErrorMsg = { fg = p.common.error, bg = p.editor.bg, bold = true },                  -- Error messages on the command line.
    StderrMsg = { fg = p.common.error, bg = p.editor.bg },                                 -- Messages in stderr from shell commands.
    StdoutMsg = { fg = p.editor.fg, bg = p.editor.bg },                                    -- Messages in stdout from shell commands.
    WinSeparator = { fg = p.ui.line, bg = p.editor.bg },                                   -- Separators between window splits.
    Folded = { fg = p.extra.fold_fg, bg = p.extra.fold_bg, italic = true },             -- Line used for closed folds.
    FoldColumn = { fg = p.extra.fold_fg, bg = p.editor.bg },                               -- 'foldcolumn'.
    SignColumn = { fg = p.extra.fold_fg, bg = p.editor.bg },                               -- Column where signs are displayed.
    IncSearch = { fg = p.editor.bg, bg = p.syntax.func },                                  -- 'incsearch' highlighting.
    Substitute = { fg = p.editor.bg, bg = p.syntax.func },                                 -- :substitute replacement text highlighting.
    LineNr = { fg = p.extra.line_number_fg, bg = p.editor.bg },                            -- Line number.
    LineNrAbove = { fg = p.extra.line_number_fg, bg = p.editor.bg },                       -- Relative number above cursor.
    LineNrBelow = { fg = p.extra.line_number_fg, bg = p.editor.bg },                       -- Relative number below cursor.
    CursorLineNr = { fg = p.syntax.func, bg = p.editor.line, bold = true },             -- Line number when cursorline is set.
    CursorLineFold = { fg = p.syntax.func, bg = p.editor.line },                           -- Like FoldColumn when cursorline is set.
    CursorLineSign = { fg = p.syntax.func, bg = p.editor.line },                           -- Like SignColumn when cursorline is set.
    MatchParen = { fg = p.common.accent, bg = p.extra.match_paren_bg },                    -- Paired bracket under/before cursor.
    ModeMsg = { fg = p.syntax.func, bg = p.editor.bg, bold = true },                    -- '-- INSERT --'.
    MsgArea = { fg = p.editor.fg, bg = p.editor.bg },                                      -- Message area.
    MsgSeparator = { fg = p.ui.line, bg = p.editor.bg },                                   -- Separator for messages.
    MoreMsg = { fg = p.syntax.func, bg = p.editor.bg },                                    -- More prompt.
    NonText = { fg = p.ui.fg, bg = p.editor.bg },                                          -- Non-printable chars.
    Normal = { fg = p.editor.fg, bg = p.editor.bg },                                       -- Normal text.
    NormalFloat = { fg = p.editor.fg, bg = p.ui.panel.bg },                                -- Floating window text.
    FloatBorder = { fg = p.ui.fg, bg = p.ui.panel.bg },                                    -- Floating window border.
    FloatTitle = { fg = p.extra.float_title_fg, bg = p.ui.panel.bg, bold = true },      -- Floating window title.
    FloatFooter = { fg = p.extra.float_title_fg, bg = p.ui.panel.bg },                     -- Floating window footer.
    NormalNC = { fg = p.editor.fg, bg = p.editor.bg },                                     -- Non-current window text.
    Pmenu = { fg = p.editor.fg, bg = p.ui.panel.bg },                                      -- Popup menu normal item.
    PmenuSel = { fg = p.editor.bg, bg = p.syntax.func },                                   -- Popup menu selected item.
    PmenuKind = { fg = p.syntax.entity, bg = p.ui.panel.bg },                              -- Popup menu kind.
    PmenuKindSel = { fg = p.editor.bg, bg = p.syntax.entity },                             -- Popup menu kind selected.
    PmenuExtra = { fg = p.syntax.comment, bg = p.ui.panel.bg },                            -- Popup menu extra text.
    PmenuExtraSel = { fg = p.editor.bg, bg = p.syntax.comment },                           -- Popup menu extra text selected.
    PmenuSbar = { fg = nil, bg = p.extra.pmenu_sbar_bg },                                -- Popup menu scrollbar.
    PmenuThumb = { fg = nil, bg = p.extra.pmenu_thumb_bg },                              -- Popup menu scrollbar thumb.
    PmenuMatch = { fg = p.common.accent, bg = p.ui.panel.bg },                             -- Popup menu match text.
    PmenuMatchSel = { fg = p.editor.bg, bg = p.common.accent },                            -- Popup menu match selected.
    ComplMatchIns = { fg = p.syntax.func, bg = p.ui.panel.bg },                            -- Current completion match.
    Question = { fg = p.syntax.func, bg = p.editor.bg },                                   -- Hit-enter prompt.
    QuickFixLine = { fg = nil, bg = p.editor.line },                                     -- Quickfix current line.
    Search = { fg = p.editor.bg, bg = p.common.accent },                                   -- Search match.
    SnippetTabstop = { fg = p.vcs.added, bg = p.editor.bg },                               -- Snippet tabstop.
    SpecialKey = { fg = p.syntax.tag, bg = p.editor.bg },                                  -- Special key.
    SpellBad = { fg = p.common.error, bg = p.editor.bg, undercurl = true },             -- Bad spelling.
    SpellCap = { fg = p.syntax.func, bg = p.editor.bg, undercurl = true },              -- Capitalization error.
    SpellLocal = { fg = p.vcs.modified, bg = p.editor.bg, undercurl = true },           -- Wrong region spelling.
    SpellRare = { fg = p.syntax.constant, bg = p.editor.bg, undercurl = true },         -- Rare word.
    StatusLine = { fg = p.editor.fg, bg = p.ui.line },                                     -- Status line current.
    StatusLineNC = { fg = p.ui.fg, bg = p.ui.line },                                       -- Status line inactive.
    StatusLineTerm = { fg = p.editor.fg, bg = p.ui.line },                                 -- Terminal status line.
    StatusLineTermNC = { fg = p.ui.fg, bg = p.ui.line },                                   -- Terminal status line inactive.
    TabLine = { fg = p.ui.fg, bg = p.editor.bg },                                          -- Tabline inactive.
    TabLineFill = { fg = nil, bg = p.editor.bg },                                        -- Tabline empty area.
    TabLineSel = { fg = p.editor.bg, bg = p.syntax.func },                                 -- Active tabline item.
    Title = { fg = p.syntax.func, bg = p.editor.bg, bold = true },                      -- Titles.
    Visual = { fg = nil, bg = p.extra.visual_bg },                                       -- Visual selection.
    VisualNOS = { fg = nil, bg = p.extra.visual_bg },                                    -- Visual NOS selection.
    WarningMsg = { fg = p.syntax.func, bg = p.editor.bg },                                 -- Warning messages.
    Whitespace = { fg = p.extra.line_number_fg, bg = p.editor.bg },                        -- Whitespace.
    WildMenu = { fg = p.editor.bg, bg = p.syntax.func },                                   -- Wildmenu selection.
    WinBar = { fg = p.editor.fg, bg = p.editor.bg },                                       -- Current window bar.
    WinBarNC = { fg = p.ui.fg, bg = p.editor.bg },                                         -- Inactive window bar.
  }
end

return M
