local g = vim.g
local o = vim.o
local cmd = vim.cmd
local api = vim.api
local Util = require("themes.util")

cmd.highlight("clear")
cmd.syntax("reset")

o.termguicolors = true
g.colors_name = "tokyonight-moon"
g.matchparen_disable_cursor_hl = 1

local transparent = false
local dim_inactive = false

local tmp = {
  bg = "#222436",
  bg_dark = "#1e2030",
  bg_dark1 = "#191B29",
  bg_highlight = "#2f334d",
  blue = "#82aaff",
  blue0 = "#3e68d7",
  blue1 = "#65bcff",
  blue2 = "#0db9d7",
  blue5 = "#89ddff",
  blue6 = "#b4f9f8",
  blue7 = "#394b70",
  comment = "#636da6",
  cyan = "#86e1fc",
  dark3 = "#545c7e",
  dark5 = "#737aa2",
  fg = "#c8d3f5",
  fg_dark = "#828bb8",
  fg_gutter = "#3b4261",
  green = "#c3e88d",
  green1 = "#4fd6be",
  green2 = "#41a6b5",
  magenta = "#c099ff",
  magenta2 = "#ff007c",
  orange = "#ff966c",
  purple = "#fca7ea",
  red = "#ff757f",
  red1 = "#c53b53",
  teal = "#4fd6be",
  terminal_black = "#444a73",
  yellow = "#ffc777",
  git = {
    add = "#b8db87",
    change = "#7ca1f2",
    delete = "#e26a75",
  },
}

local c = {
  bg = "#222436",
  bg_dark = "#1e2030",
  bg_dark1 = "#191B29",
  bg_highlight = "#2f334d",
  blue = "#82aaff",
  blue0 = "#3e68d7",
  blue1 = "#65bcff",
  blue2 = "#0db9d7",
  blue5 = "#89ddff",
  blue6 = "#b4f9f8",
  blue7 = "#394b70",
  comment = "#636da6",
  cyan = "#86e1fc",
  dark3 = "#545c7e",
  dark5 = "#737aa2",
  fg = "#c8d3f5",
  fg_dark = "#828bb8",
  fg_gutter = "#3b4261",
  green = "#c3e88d",
  green1 = "#4fd6be",
  green2 = "#41a6b5",
  magenta = "#c099ff",
  magenta2 = "#ff007c",
  orange = "#ff966c",
  purple = "#fca7ea",
  red = "#ff757f",
  red1 = "#c53b53",
  teal = "#4fd6be",
  terminal_black = "#444a73",
  yellow = "#ffc777",
  git = {
    add = "#b8db87",
    change = "#7ca1f2",
    delete = "#e26a75",
    -- temporary
    ignore = tmp.dark3,
  },

  -- temporary only
  dark = Util.blend(tmp.bg_dark, 0.8, "#000000"),
  bg_sidebar = tmp.bg_dark,
  bg_float = tmp.bg_dark,
  bg_visual = Util.blend_bg(tmp.blue0, 0.4, tmp.bg),
  bg_search = tmp.blue0,
  fg_sidebar = tmp.fg_dark,
  fg_float = tmp.fg,
  error = tmp.red1,
  todo = tmp.blue,
  warning = tmp.yellow,
  info = tmp.blue2,
  hint = tmp.teal,
  black = Util.blend_bg(tmp.bg, 0.8, "#000000"),
  border_highlight = Util.blend_bg(tmp.blue1, 0.8),
  border = tmp.black,
  bg_popup = tmp.bg_dark,
  bg_statusline = tmp.bg_dark,

  diff = {
    add = Util.blend_bg(tmp.green2, 0.15, tmp.bg),
    delete = Util.blend_bg(tmp.red1, 0.15, tmp.bg),
    change = Util.blend_bg(tmp.blue7, 0.15, tmp.bg),
    text = tmp.blue7,
  }
}

local s = {
  Comment = { fg = c.comment },                                           -- any comment
  ColorColumn = { bg = c.black },                                         -- used for the columns set with 'colorcolumn'
  Conceal = { fg = c.dark5 },                                             -- placeholder characters substituted for concealed text (see 'conceallevel')
  Cursor = { fg = c.bg, bg = c.fg },                                      -- character under the cursor
  lCursor = { fg = c.bg, bg = c.fg },                                     -- the character under the cursor when |language-mapping| is used (see 'guicursor')
  CursorIM = { fg = c.bg, bg = c.fg },                                    -- like Cursor, but used when in IME mode |CursorIM|
  CursorColumn = { bg = c.bg_highlight },                                 -- Screen-column at the cursor, when 'cursorcolumn' is set.
  CursorLine = { bg = c.bg_highlight },                                   -- Screen-line at the cursor, when 'cursorline' is set.  Low-priority if foreground (ctermfg OR guifg) is not set.
  Directory = { fg = c.blue },                                            -- directory names (and other special names in listings)
  DiffAdd = { bg = c.diff.add },                                          -- diff mode: Added line |diff.txt|
  DiffChange = { bg = c.diff.change },                                    -- diff mode: Changed line |diff.txt|
  DiffDelete = { bg = c.diff.delete },                                    -- diff mode: Deleted line |diff.txt|
  DiffText = { bg = c.diff.text },                                        -- diff mode: Changed text within a changed line |diff.txt|
  EndOfBuffer = { fg = c.bg },                                            -- filler lines (~) after the end of the buffer.  By default, this is highlighted like |hl-NonText|.
  ErrorMsg = { fg = c.error },                                            -- error messages on the command line
  VertSplit = { fg = c.border },                                          -- the column separating vertically split windows
  -- WinSeparator = { fg = c.border, bold = false },                          -- the column separating vertically split windows
  WinSeparator = { fg = c.border_highlight, bold = true },
  Folded = { fg = c.blue, bg = c.fg_gutter },                             -- line used for closed folds
  FoldColumn = { bg = transparent and c.none or c.bg, fg = c.comment },   -- 'foldcolumn'
  SignColumn = { bg = transparent and c.none or c.bg, fg = c.fg_gutter }, -- column where |signs| are displayed
  SignColumnSB = { bg = c.bg_sidebar, fg = c.fg_gutter },                 -- column where |signs| are displayed
  Substitute = { bg = c.red, fg = c.black },                              -- |:substitute| replacement text highlighting
  LineNr = { fg = c.fg_gutter },                                          -- Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
  CursorLineNr = { fg = c.orange, bold = true },                          -- Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
  LineNrAbove = { fg = c.fg_gutter },
  LineNrBelow = { fg = c.fg_gutter },
  MatchParen = { fg = c.orange, bold = true },                                                 -- The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
  ModeMsg = { fg = c.fg_dark, bold = true },                                                   -- 'showmode' message (e.g., "-- INSERT -- ")
  MsgArea = { fg = c.fg_dark },                                                                -- Area for messages and cmdline
  MoreMsg = { fg = c.blue },                                                                   -- |more-prompt|
  NonText = { fg = c.dark3 },                                                                  -- '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line). See also |hl-EndOfBuffer|.
  Normal = { fg = c.fg, bg = transparent and c.none or c.bg },                                 -- normal text
  NormalNC = { fg = c.fg, bg = transparent and c.none or dim_inactive and c.bg_dark or c.bg }, -- normal text in non-current windows
  NormalSB = { fg = c.fg_sidebar, bg = c.bg_sidebar },                                         -- normal text in sidebar
  NormalFloat = { fg = c.fg_float, bg = c.bg_float },                                          -- Normal text in floating windows.
  FloatBorder = { fg = c.border_highlight, bg = c.bg_float },
  FloatTitle = { fg = c.border_highlight, bg = c.bg_float },
  Pmenu = { bg = c.bg_popup, fg = c.fg },                                 -- Popup menu: normal item.
  PmenuMatch = { bg = c.bg_popup, fg = c.blue1 },                         -- Popup menu: Matched text in normal item.
  PmenuSel = { bg = Util.blend_bg(c.fg_gutter, 0.8, tmp.bg) },                    -- Popup menu: selected item.
  PmenuMatchSel = { bg = Util.blend_bg(c.fg_gutter, 0.8), fg = c.blue1 }, -- Popup menu: Matched text in selected item.
  PmenuSbar = { bg = Util.blend_fg(c.bg_popup, 0.95, tmp.fg) },                   -- Popup menu: scrollbar.
  PmenuThumb = { bg = c.fg_gutter },                                      -- Popup menu: Thumb of the scrollbar.
  Question = { fg = c.blue },                                             -- |hit-enter| prompt and yes/no questions
  QuickFixLine = { bg = c.bg_visual, bold = true },                       -- Current |quickfix| item in the quickfix window. Combined with |hl-CursorLine| when the cursor is there.
  Search = { bg = c.bg_search, fg = c.fg },                               -- Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
  IncSearch = { bg = c.orange, fg = c.black },                            -- 'incsearch' highlighting; also used for the text replaced with ":s///c"
  CurSearch = { link = "IncSearch" },
  SpecialKey = { fg = c.dark3 },                                          -- Unprintable characters: text displayed differently from what it really is.  But not 'listchars' whitespace. |hl-Whitespace|
  SpellBad = { sp = c.error, undercurl = true },                          -- Word that is not recognized by the spellchecker. |spell| Combined with the highlighting used otherwise.
  SpellCap = { sp = c.warning, undercurl = true },                        -- Word that should start with a capital. |spell| Combined with the highlighting used otherwise.
  SpellLocal = { sp = c.info, undercurl = true },                         -- Word that is recognized by the spellchecker as one that is used in another region. |spell| Combined with the highlighting used otherwise.
  SpellRare = { sp = c.hint, undercurl = true },                          -- Word that is recognized by the spellchecker as one that is hardly ever used.  |spell| Combined with the highlighting used otherwise.
  StatusLine = { fg = c.fg_sidebar, bg = c.bg_statusline },               -- status line of current window
  StatusLineNC = { fg = c.fg_gutter, bg = c.bg_statusline },              -- status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
  TabLine = { bg = c.bg_statusline, fg = c.fg_gutter },                   -- tab pages line, not active tab page label
  TabLineFill = { bg = c.black },                                         -- tab pages line, where there are no labels
  TabLineSel = { fg = c.black, bg = c.blue },                             -- tab pages line, active tab page label
  Title = { fg = c.blue, bold = true },                                   -- titles for output from ":set all", ":autocmd" etc.
  Visual = { bg = c.bg_visual },                                          -- Visual mode selection
  VisualNOS = { bg = c.bg_visual },                                       -- Visual mode selection when vim is "Not Owning the Selection".
  WarningMsg = { fg = c.warning },                                        -- warning messages
  Whitespace = { fg = c.fg_gutter },                                      -- "nbsp", "space", "tab" and "trail" in 'listchars'
  WildMenu = { bg = c.bg_visual },                                        -- current match in 'wildmenu' completion
  WinBar = { link = "StatusLine" },                                       -- window bar
  WinBarNC = { link = "StatusLineNC" },                                   -- window bar in inactive windows

  Bold = { bold = true, fg = c.fg },                                      -- (preferred) any bold text
  Character = { fg = c.green },                                           --  a character constant: 'c', '\n'
  Constant = { fg = c.orange },                                           -- (preferred) any constant
  Debug = { fg = c.orange },                                              --    debugging statements
  Delimiter = { link = "Special" },                                       --  character that needs attention
  Error = { fg = c.error },                                               -- (preferred) any erroneous construct
  Function = { fg = c.blue },                                             -- function name (also: methods for classes)
  Identifier = { fg = c.magenta },                                        -- (preferred) any variable name
  Italic = { italic = true, fg = c.fg },                                  -- (preferred) any italic text
  Keyword = { fg = c.cyan },                                              --  any other keyword
  Operator = { fg = c.blue5 },                                            -- "sizeof", "+", "*", etc.
  PreProc = { fg = c.cyan },                                              -- (preferred) generic Preprocessor
  Special = { fg = c.blue1 },                                             -- (preferred) any special symbol
  Statement = { fg = c.magenta },                                         -- (preferred) any statement
  String = { fg = c.green },                                              --   a string constant: "this is a string"
  Todo = { bg = c.yellow, fg = c.bg },                                    -- (preferred) anything that needs extra attention; mostly the keywords TODO FIXME and XXX
  Type = { fg = c.blue1 },                                                -- (preferred) int, long, char, etc.
  Underlined = { underline = true },                                      -- (preferred) text that stands out, HTML links
  debugBreakpoint = { bg = Util.blend_bg(c.info, 0.1, tmp.bg), fg = c.info },     -- used for breakpoint colors in terminal-debug
  debugPC = { bg = c.bg_sidebar },                                        -- used for highlighting the current line in terminal-debug
  dosIniLabel = { link = "@property" },
  helpCommand = { bg = c.terminal_black, fg = c.blue },
  htmlH1 = { fg = c.magenta, bold = true },
  htmlH2 = { fg = c.blue, bold = true },
  qfFileName = { fg = c.blue },
  qfLineNr = { fg = c.dark5 },

  -- These groups are for the native LSP client. Some other LSP clients may
  -- use these groups, or use their own.
  LspReferenceText = { bg = c.fg_gutter },  -- used for highlighting "text" references
  LspReferenceRead = { bg = c.fg_gutter },  -- used for highlighting "read" references
  LspReferenceWrite = { bg = c.fg_gutter }, -- used for highlighting "write" references
  LspSignatureActiveParameter = { bg = Util.blend_bg(c.bg_visual, 0.4, tmp.bg), bold = true },
  LspCodeLens = { fg = c.comment },
  LspInlayHint = { bg = Util.blend_bg(c.blue7, 0.1, tmp.bg), fg = c.dark3 },
  LspInfoBorder = { fg = c.border_highlight, bg = c.bg_float },

  -- diagnostics
  DiagnosticError = { fg = c.error },                                                 -- Used as the base highlight group. Other Diagnostic highlights link to this by default
  DiagnosticWarn = { fg = c.warning },                                                -- Used as the base highlight group. Other Diagnostic highlights link to this by default
  DiagnosticInfo = { fg = c.info },                                                   -- Used as the base highlight group. Other Diagnostic highlights link to this by default
  DiagnosticHint = { fg = c.hint },                                                   -- Used as the base highlight group. Other Diagnostic highlights link to this by default
  DiagnosticUnnecessary = { fg = c.terminal_black },                                  -- Used as the base highlight group. Other Diagnostic highlights link to this by default
  DiagnosticVirtualTextError = { bg = Util.blend_bg(c.error, 0.1, tmp.bg), fg = c.error },    -- Used for "Error" diagnostic virtual text
  DiagnosticVirtualTextWarn = { bg = Util.blend_bg(c.warning, 0.1, tmp.bg), fg = c.warning }, -- Used for "Warning" diagnostic virtual text
  DiagnosticVirtualTextInfo = { bg = Util.blend_bg(c.info, 0.1, tmp.bg), fg = c.info },       -- Used for "Information" diagnostic virtual text
  DiagnosticVirtualTextHint = { bg = Util.blend_bg(c.hint, 0.1, tmp.bg), fg = c.hint },       -- Used for "Hint" diagnostic virtual text
  DiagnosticUnderlineError = { undercurl = true, sp = c.error },                      -- Used to underline "Error" diagnostics
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.warning },                     -- Used to underline "Warning" diagnostics
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.info },                        -- Used to underline "Information" diagnostics
  DiagnosticUnderlineHint = { undercurl = true, sp = c.hint },                        -- Used to underline "Hint" diagnostics

  -- Health
  healthError = { fg = c.error },
  healthSuccess = { fg = c.green1 },
  healthWarning = { fg = c.warning },

  -- diff (not needed anymore?)
  diffAdded = { bg = c.diff.add, fg = c.git.add },
  diffRemoved = { bg = c.diff.delete, fg = c.git.delete },
  diffChanged = { bg = c.diff.change, fg = c.git.change },
  diffOldFile = { fg = c.blue1, bg = c.diff.delete },
  diffNewFile = { fg = c.blue1, bg = c.diff.add },
  diffFile = { fg = c.blue },
  diffLine = { fg = c.comment },
  diffIndexLine = { fg = c.magenta },
  helpExample = { fg = c.comment },

  ["@annotation"] = { link = "PreProc" },
  ["@attribute"] = { link = "PreProc" },
  ["@boolean"] = { link = "Boolean" },
  ["@character"] = { link = "Character" },
  ["@character.printf"] = { link = "SpecialChar" },
  ["@character.special"] = { link = "SpecialChar" },
  ["@comment"] = { link = "Comment" },
  ["@comment.error"] = { fg = c.error },
  ["@comment.hint"] = { fg = c.hint },
  ["@comment.info"] = { fg = c.info },
  ["@comment.note"] = { fg = c.hint },
  ["@comment.todo"] = { fg = c.todo },
  ["@comment.warning"] = { fg = c.warning },
  ["@constant"] = { link = "Constant" },
  ["@constant.builtin"] = { link = "Special" },
  ["@constant.macro"] = { link = "Define" },
  ["@constructor"] = { fg = c.magenta }, -- For constructor calls and definitions: `= { }` in Lua, and Java constructors.
  ["@constructor.tsx"] = { fg = c.blue1 },
  ["@diff.delta"] = { link = "DiffChange" },
  ["@diff.minus"] = { link = "DiffDelete" },
  ["@diff.plus"] = { link = "DiffAdd" },
  ["@function"] = { link = "Function" },
  ["@function.builtin"] = { link = "Special" },
  ["@function.call"] = { link = "@function" },
  ["@function.macro"] = { link = "Macro" },
  ["@function.method"] = { link = "Function" },
  ["@function.method.call"] = { link = "@function.method" },
  ["@keyword"] = { fg = c.purple }, -- For keywords that don't fall in previous categories.
  ["@keyword.conditional"] = { link = "Conditional" },
  ["@keyword.coroutine"] = { link = "@keyword" },
  ["@keyword.debug"] = { link = "Debug" },
  ["@keyword.directive"] = { link = "PreProc" },
  ["@keyword.directive.define"] = { link = "Define" },
  ["@keyword.exception"] = { link = "Exception" },
  ["@keyword.function"] = { fg = c.magenta }, -- For keywords used to define a function.
  ["@keyword.import"] = { link = "Include" },
  ["@keyword.operator"] = { link = "@operator" },
  ["@keyword.repeat"] = { link = "Repeat" },
  ["@keyword.return"] = { link = "@keyword" },
  ["@keyword.storage"] = { link = "StorageClass" },
  ["@label"] = { fg = c.blue }, -- For labels: `label:` in C and `:label:` in Lua.
  ["@markup"] = { link = "@none" },
  ["@markup.emphasis"] = { italic = true },
  ["@markup.environment"] = { link = "Macro" },
  ["@markup.environment.name"] = { link = "Type" },
  ["@markup.heading"] = { link = "Title" },
  ["@markup.italic"] = { italic = true },
  ["@markup.link"] = { fg = c.teal },
  ["@markup.link.label"] = { link = "SpecialChar" },
  ["@markup.link.label.symbol"] = { link = "Identifier" },
  ["@markup.link.url"] = { link = "Underlined" },
  ["@markup.list"] = { fg = c.blue5 },          -- For special punctutation that does not fall in the categories before.
  ["@markup.list.checked"] = { fg = c.green1 }, -- For brackets and parens.
  ["@markup.list.markdown"] = { fg = c.orange, bold = true },
  ["@markup.list.unchecked"] = { fg = c.blue }, -- For brackets and parens.
  ["@markup.math"] = { link = "Special" },
  ["@markup.raw"] = { link = "String" },
  ["@markup.raw.markdown_inline"] = { bg = c.terminal_black, fg = c.blue },
  ["@markup.strikethrough"] = { strikethrough = true },
  ["@markup.strong"] = { bold = true },
  ["@markup.underline"] = { underline = true },
  ["@module"] = { link = "Directory" },
  ["@module.builtin"] = { fg = c.red }, -- Variable names that are defined by the languages, like `this` or `self`.
  ["@namespace.builtin"] = { link = "@variable.builtin" },
  ["@none"] = {},
  ["@number"] = { link = "Number" },
  ["@number.float"] = { link = "Float" },
  ["@operator"] = { fg = c.blue5 },                      -- For any operator: `+`, but also `->` and `*` in C.
  ["@property"] = { fg = c.green1 },
  ["@punctuation.bracket"] = { fg = c.fg_dark },         -- For brackets and parens.
  ["@punctuation.delimiter"] = { fg = c.blue5 },         -- For delimiters ie: `.`
  ["@punctuation.special"] = { fg = c.blue5 },           -- For special symbols (e.g. `{}` in string interpolation)
  ["@punctuation.special.markdown"] = { fg = c.orange }, -- For special symbols (e.g. `{}` in string interpolation)
  ["@string"] = { link = "String" },
  ["@string.documentation"] = { fg = c.yellow },
  ["@string.escape"] = { fg = c.magenta }, -- For escape characters within a string.
  ["@string.regexp"] = { fg = c.blue6 },   -- For regexes.
  ["@tag"] = { link = "Label" },
  ["@tag.attribute"] = { link = "@property" },
  ["@tag.delimiter"] = { link = "Delimiter" },
  ["@tag.delimiter.tsx"] = { fg = Util.blend_bg(c.blue, 0.7, tmp.bg) },
  ["@tag.tsx"] = { fg = c.red },
  ["@tag.javascript"] = { fg = c.red },
  ["@type"] = { link = "Type" },
  ["@type.builtin"] = { fg = Util.blend_bg(c.blue1, 0.8, tmp.bg) },
  ["@type.definition"] = { link = "Typedef" },
  ["@type.qualifier"] = { link = "@keyword" },
  ["@variable"] = { fg = c.fg },                                           -- Any variable name that does not have another highlight.
  ["@variable.builtin"] = { fg = c.red },                                  -- Variable names that are defined by the languages, like `this` or `self`.
  ["@variable.member"] = { fg = c.green1 },                                -- For fields.
  ["@variable.parameter"] = { fg = c.yellow },                             -- For parameters of a function.
  ["@variable.parameter.builtin"] = { fg = Util.blend_fg(c.yellow, 0.8, tmp.fg) }, -- For builtin parameters of a function, e.g. "..." or Smali's p[1-99]

  -- stylua: ignore
  ["@lsp.type.boolean"] = { link = "@boolean" },
  ["@lsp.type.builtinType"] = { link = "@type.builtin" },
  ["@lsp.type.comment"] = { link = "@comment" },
  ["@lsp.type.decorator"] = { link = "@attribute" },
  ["@lsp.type.deriveHelper"] = { link = "@attribute" },
  ["@lsp.type.enum"] = { link = "@type" },
  ["@lsp.type.enumMember"] = { link = "@constant" },
  ["@lsp.type.escapeSequence"] = { link = "@string.escape" },
  ["@lsp.type.formatSpecifier"] = { link = "@markup.list" },
  ["@lsp.type.generic"] = { link = "@variable" },
  ["@lsp.type.interface"] = { fg = Util.blend_fg(c.blue1, 0.7, tmp.fg) },
  ["@lsp.type.keyword"] = { link = "@keyword" },
  ["@lsp.type.lifetime"] = { link = "@keyword.storage" },
  ["@lsp.type.namespace"] = { link = "@module" },
  ["@lsp.type.namespace.python"] = { link = "@variable" },
  ["@lsp.type.number"] = { link = "@number" },
  ["@lsp.type.operator"] = { link = "@operator" },
  ["@lsp.type.parameter"] = { link = "@variable.parameter" },
  ["@lsp.type.property"] = { link = "@property" },
  ["@lsp.type.selfKeyword"] = { link = "@variable.builtin" },
  ["@lsp.type.selfTypeKeyword"] = { link = "@variable.builtin" },
  ["@lsp.type.string"] = { link = "@string" },
  ["@lsp.type.typeAlias"] = { link = "@type.definition" },
  ["@lsp.type.unresolvedReference"] = { undercurl = true, sp = c.error },
  ["@lsp.type.variable"] = {}, -- use treesitter styles for regular variables
  ["@lsp.typemod.class.defaultLibrary"] = { link = "@type.builtin" },
  ["@lsp.typemod.enum.defaultLibrary"] = { link = "@type.builtin" },
  ["@lsp.typemod.enumMember.defaultLibrary"] = { link = "@constant.builtin" },
  ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
  ["@lsp.typemod.keyword.async"] = { link = "@keyword.coroutine" },
  ["@lsp.typemod.keyword.injected"] = { link = "@keyword" },
  ["@lsp.typemod.macro.defaultLibrary"] = { link = "@function.builtin" },
  ["@lsp.typemod.method.defaultLibrary"] = { link = "@function.builtin" },
  ["@lsp.typemod.operator.injected"] = { link = "@operator" },
  ["@lsp.typemod.string.injected"] = { link = "@string" },
  ["@lsp.typemod.struct.defaultLibrary"] = { link = "@type.builtin" },
  ["@lsp.typemod.type.defaultLibrary"] = { fg = Util.blend_bg(c.blue1, 0.8, tmp.bg) },
  ["@lsp.typemod.typeAlias.defaultLibrary"] = { fg = Util.blend_bg(c.blue1, 0.8, tmp.bg) },
  ["@lsp.typemod.variable.callable"] = { link = "@function" },
  ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
  ["@lsp.typemod.variable.injected"] = { link = "@variable" },
  ["@lsp.typemod.variable.static"] = { link = "@constant" },

  NeoTreeDimText = { fg = c.fg_gutter },
  NeoTreeFileName = { fg = c.fg_sidebar },
  NeoTreeGitModified = { fg = c.orange },
  NeoTreeGitStaged = { fg = c.green1 },
  NeoTreeGitUntracked = { fg = c.magenta },
  NeoTreeNormal = { fg = c.fg_sidebar, bg = c.bg_sidebar },
  NeoTreeNormalNC = { fg = c.fg_sidebar, bg = c.bg_sidebar },
  NeoTreeTabActive = { fg = c.blue, bg = c.bg_dark, bold = true },
  NeoTreeTabInactive = { fg = c.dark3, bg = c.dark },
  NeoTreeTabSeparatorActive = { fg = c.blue, bg = c.bg_dark },
  NeoTreeTabSeparatorInactive = { fg = c.bg, bg = c.dark },

  BlinkCmpDoc = { fg = c.fg, bg = c.bg_float },
  BlinkCmpDocBorder = { fg = c.border_highlight, bg = c.bg_float },
  BlinkCmpGhostText = { fg = c.terminal_black },
  BlinkCmpKindCodeium = { fg = c.teal, bg = c.none },
  BlinkCmpKindCopilot = { fg = c.teal, bg = c.none },
  BlinkCmpKindDefault = { fg = c.fg_dark, bg = c.none },
  BlinkCmpKindSupermaven = { fg = c.teal, bg = c.none },
  BlinkCmpKindTabNine = { fg = c.teal, bg = c.none },
  BlinkCmpLabel = { fg = c.fg, bg = c.none },
  BlinkCmpLabelDeprecated = { fg = c.fg_gutter, bg = c.none, strikethrough = true },
  BlinkCmpLabelMatch = { fg = c.blue1, bg = c.none },
  BlinkCmpMenu = { fg = c.fg, bg = c.bg_float },
  BlinkCmpMenuBorder = { fg = c.border_highlight, bg = c.bg_float },
  BlinkCmpSignatureHelp = { fg = c.fg, bg = c.bg_float },
  BlinkCmpSignatureHelpBorder = { fg = c.border_highlight, bg = c.bg_float },
  BlinkCmpKindArray = { link = "@punctuation.bracket" },
  BlinkCmpKindBoolean = { link = "@boolean" },
  BlinkCmpKindClass = { link = "@type" },
  BlinkCmpKindColor = { link = "Special" },
  BlinkCmpKindConstant = { link = "@constant" },
  BlinkCmpKindConstructor = { link = "@constructor" },
  BlinkCmpKindEnum = { link = "@lsp.type.enum" },
  BlinkCmpKindEnumMember = { link = "@lsp.type.enumMember" },
  BlinkCmpKindEvent = { link = "Special" },
  BlinkCmpKindField = { link = "@variable.member" },
  BlinkCmpKindFile = { link = "Normal" },
  BlinkCmpKindFolder = { link = "Directory" },
  BlinkCmpKindFunction = { link = "@function" },
  BlinkCmpKindInterface = { link = "@lsp.type.interface" },
  BlinkCmpKindKey = { link = "@variable.member" },
  BlinkCmpKindKeyword = { link = "@lsp.type.keyword" },
  BlinkCmpKindMethod = { link = "@function.method" },
  BlinkCmpKindModule = { link = "@module" },
  BlinkCmpKindNamespace = { link = "@module" },
  BlinkCmpKindNull = { link = "@constant.builtin" },
  BlinkCmpKindNumber = { link = "@number" },
  BlinkCmpKindObject = { link = "@constant" },
  BlinkCmpKindOperator = { link = "@operator" },
  BlinkCmpKindPackage = { link = "@module" },
  BlinkCmpKindProperty = { link = "@property" },
  BlinkCmpKindReference = { link = "@markup.link" },
  BlinkCmpKindSnippet = { link = "Conceal" },
  BlinkCmpKindString = { link = "@string" },
  BlinkCmpKindStruct = { link = "@lsp.type.struct" },
  BlinkCmpKindUnit = { link = "@lsp.type.struct" },
  BlinkCmpKindText = { link = "@markup" },
  BlinkCmpKindTypeParameter = { link = "@lsp.type.typeParameter" },
  BlinkCmpKindVariable = { link = "@variable" },
  BlinkCmpKindValue = { link = "@string" },

  RenderMarkdownBullet = { fg = c.orange },    -- horizontal rule
  RenderMarkdownCode = { bg = c.bg_dark },
  RenderMarkdownDash = { fg = c.orange },      -- horizontal rule
  RenderMarkdownTableHead = { fg = c.red },
  RenderMarkdownTableRow = { fg = c.orange },
  RenderMarkdownCodeInline = {link = "@markup.raw.markdown_inline"}
}

local hl = api.nvim_set_hl
for key, val in pairs(s) do
  hl(0, key, val)
end
