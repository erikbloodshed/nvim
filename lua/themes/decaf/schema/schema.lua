local M = {}

function M.get(c, o)
  local t = o.transparency
  local t_co = t and c.none
  local s_transp = t and c.surface1
  local f_transp = (o.float.transparent and vim.o.winblend == 0) and c.none
  local p_transp = (t and vim.o.pumblend == 0) and c.none
  local error = c.red
  local warn = c.yellow
  local info = c.sky
  local hint = c.teal
  local ok = c.green
  local active_bg = t_co or c.mantle
  local inactive_bg = t_co or c.base
  local h = {}

  h = {
    -- {{{ Editor
    ColorColumn                                = { bg = c.surface0 },
    Conceal                                    = { fg = c.overlay1 },
    Cursor                                     = { fg = c.base, bg = c.rosewater },
    lCursor                                    = { link = "Cursor" },
    CursorIM                                   = { link = "Cursor" },
    CursorColumn                               = { bg = c.mantle },
    CursorLine                                 = { bg = c.bg_line },
    Directory                                  = { fg = c.blue },
    EndOfBuffer                                = { fg = c.base, },
    ErrorMsg                                   = { fg = c.red, bold = true, italic = true },
    VertSplit                                  = { fg = s_transp or c.crust },
    Folded                                     = { fg = c.blue, bg = t_co or c.surface1 },
    FoldColumn                                 = { fg = c.overlay0 },
    SignColumn                                 = { fg = c.surface1 },
    SignColumnSB                               = { bg = c.crust, fg = c.surface1 },
    Substitute                                 = { bg = c.surface1, fg = c.pink },
    LineNr                                     = { fg = c.surface1 },
    CursorLineNr                               = { fg = c.lavender },
    MatchParen                                 = { fg = c.peach, bg = c.surface1, bold = true },
    ModeMsg                                    = { fg = c.text, bold = true },
    MsgSeparator                               = {},
    MoreMsg                                    = { fg = c.blue },
    NonText                                    = { fg = c.overlay0 },
    Normal                                     = { fg = c.text, bg = t_co or c.base },
    NormalNC                                   = { fg = c.text, bg = t_co or c.dim, },
    NormalSB                                   = { fg = c.text, bg = c.crust },
    NormalFloat                                = { fg = c.text, bg = f_transp or c.mantle },
    FloatBorder                                = { fg = c.lavender, bg = c.mantle },
    FloatTitle                                 = o.float.solid and { fg = c.crust, bg = c.lavender, }
        or { fg = c.subtext0, bg = f_transp or c.mantle },
    FloatShadow                                = { fg = f_transp or c.overlay0 },
    Pmenu                                      = { bg = p_transp or c.mantle, fg = c.overlay2, },
    PmenuSel                                   = { bg = c.surface0, bold = true },
    PmenuSbar                                  = { bg = c.surface0 },
    PmenuThumb                                 = { bg = c.overlay0 },
    PmenuExtra                                 = { fg = c.overlay0 },
    PmenuExtraSel                              = { fg = c.overlay0, bold = true },
    Question                                   = { fg = c.blue },
    QuickFixLine                               = { bg = c.surface1, bold = true },
    Search                                     = { bg = c.bg_search, fg = c.text },
    IncSearch                                  = { bg = c.bg_incsearch, fg = c.mantle },
    CurSearch                                  = { bg = c.red, fg = c.mantle },
    SpecialKey                                 = { link = "NonText" },
    SpellBad                                   = { sp = c.red, undercurl = true },
    SpellCap                                   = { sp = c.yellow, undercurl = true },
    SpellLocal                                 = { sp = c.blue, undercurl = true },
    SpellRare                                  = { sp = c.green, undercurl = true },
    StatusLine                                 = { fg = c.text, bg = t_co or c.mantle },
    StatusLineNC                               = { fg = c.surface1, bg = t_co or c.mantle },

    StatusLineNormal                           = { bg = c.blue, fg = c.crust, bold = true },
    StatusLineInsert                           = { bg = c.green, fg = c.crust, bold = true },
    StatusLineVisual                           = { bg = c.mauve, fg = c.crust, bold = true },
    StatusLineCommand                          = { bg = c.yellow, fg = c.crust, bold = true },
    StatusLineReplace                          = { bg = c.maroon, fg = c.crust, bold = true },
    StatusLineTerminal                         = { bg = c.green, fg = c.crust, bold = true },
    StatusLineGit                              = { fg = c.peach },
    StatusLineModified                         = { fg = c.yellow },
    StatusLineFile                             = { fg = c.text },
    StatusLineDiagError                        = { link = "DiagnosticError" },
    StatusLineDiagWarn                         = { link = "DiagnosticWarn" },
    StatusLineDiagHint                         = { link = "DiagnosticHint" },
    StatusLineDiagInfo                         = { link = "DiagnosticInfo" },
    StatusLineLsp                              = { fg = c.green },
    StatusLineLabel                            = { fg = c.surface1 },
    StatusLineValue                            = { fg = c.peach },
    StatusLineSeparator                        = { fg = c.surface0 },

    TabLine                                    = { bg = c.crust, fg = c.overlay0 },
    TabLineFill                                = { bg = t_co or c.mantle },
    TabLineSel                                 = { link = "Normal" },
    TermCursor                                 = { fg = c.base, bg = c.rosewater },
    TermCursorNC                               = { fg = c.base, bg = c.overlay2 },
    Title                                      = { fg = c.blue, bold = true },
    Visual                                     = { bg = c.surface1, bold = true },
    VisualNOS                                  = { link = "Visual" },
    WarningMsg                                 = { fg = c.yellow },
    Whitespace                                 = { fg = c.surface1 },
    WildMenu                                   = { bg = c.overlay0 },
    WinBar                                     = { fg = c.rosewater },
    WinBarNC                                   = { link = "WinBar" },
    WinSeparator                               = { fg = s_transp or c.crust },
    -- }}}
    -- {{{ Native LSP
    DiagnosticVirtualTextError                 = { bg = t_co or c.bg_dvt_error, fg = error, italic = true, },
    DiagnosticVirtualTextWarn                  = { bg = t_co or c.bg_dvt_warn, fg = warn, italic = true, },
    DiagnosticVirtualTextInfo                  = { bg = t_co or c.bg_dvt_info, fg = info, italic = true, },
    DiagnosticVirtualTextHint                  = { bg = t_co or c.bg_dvt_hint, fg = hint, italic = true, },
    DiagnosticVirtualTextOk                    = { bg = t_co or c.bg_dvt_ok, fg = ok, italic = true, },

    DiagnosticError                            = { fg = error, italic = true },
    DiagnosticWarn                             = { fg = warn, italic = true },
    DiagnosticInfo                             = { fg = info, italic = true },
    DiagnosticHint                             = { fg = hint, italic = true },
    DiagnosticOk                               = { fg = ok, italic = true },

    DiagnosticUnderlineError                   = { undercurl = true, sp = error },
    DiagnosticUnderlineWarn                    = { undercurl = true, sp = warn },
    DiagnosticUnderlineInfo                    = { undercurl = true, sp = info },
    DiagnosticUnderlineHint                    = { undercurl = true, sp = hint },
    DiagnosticUnderlineOk                      = { undercurl = true, sp = ok },

    DiagnosticFloatingError                    = { fg = error },
    DiagnosticFloatingWarn                     = { fg = warn },
    DiagnosticFloatingInfo                     = { fg = info },
    DiagnosticFloatingHint                     = { fg = hint },
    DiagnosticFloatingOk                       = { fg = ok },

    DiagnosticSignError                        = { link = "DiagnosticFloatingError" },
    DiagnosticSignWarn                         = { link = "DiagnosticFloatingWarn" },
    DiagnosticSignInfo                         = { link = "DiagnosticFloatingInfo" },
    DiagnosticSignHint                         = { link = "DiagnosticFloatingHint" },
    DiagnosticSignOk                           = { link = "DiagnosticFloatingOk" },

    LspDiagnosticsDefaultError                 = { link = "DiagnosticFloatingError" },
    LspDiagnosticsDefaultWarning               = { link = "DiagnosticFloatingWarn" },
    LspDiagnosticsDefaultInformation           = { link = "DiagnosticFloatingInfo" },
    LspDiagnosticsDefaultHint                  = { link = "DiagnosticFloatingHint" },

    LspDiagnosticsError                        = { link = "DiagnosticFloatingError" },
    LspDiagnosticsWarning                      = { link = "DiagnosticFloatingWarn" },
    LspDiagnosticsInformation                  = { link = "DiagnosticFloatingInfo" },
    LspDiagnosticsHint                         = { link = "DiagnosticFloatingHint" },

    LspDiagnosticsVirtualTextError             = { link = "DiagnosticError" },
    LspDiagnosticsVirtualTextWarning           = { link = "DiagnosticWarn" },
    LspDiagnosticsVirtualTextInformation       = { link = "DiagnosticInfo" },
    LspDiagnosticsVirtualTextHint              = { link = "DiagnosticHint" },

    LspDiagnosticsUnderlineError               = { link = "DiagnosticUnderlineError" },
    LspDiagnosticsUnderlineWarning             = { link = "DiagnosticUnderlineWarn" },
    LspDiagnosticsUnderlineInformation         = { link = "DiagnosticUnderlineInfo" },
    LspDiagnosticsUnderlineHint                = { link = "DiagnosticUnderlineHint" },

    LspSignatureActiveParameter                = { bg = c.surface0, bold = true },
    LspCodeLens                                = { fg = c.overlay0 },
    LspCodeLensSeparator                       = { link = "LspCodeLens" },
    LspInlayHint                               = { fg = c.overlay0, bg = t_co or c.bg_line },
    LspInfoBorder                              = { link = "FloatBorder" },
    LspReferenceText                           = { bg = c.surface1 },
    LspReferenceRead                           = { link = "LspReferenceText" },
    LspReferenceWrite                          = { link = "LspReferenceText" }, -- }}}
    -- {{{ Syntax
    Comment                                    = { fg = c.overlay2, italic = true },
    SpecialComment                             = { link = "Special" },
    Constant                                   = { fg = c.peach },
    String                                     = { fg = c.green },
    Character                                  = { fg = c.teal },
    Number                                     = { link = "Constant" },
    Float                                      = { link = "Constant" },
    Boolean                                    = { link = "Constant" },
    Identifier                                 = { fg = c.flamingo },
    Function                                   = { fg = c.blue },
    Statement                                  = { fg = c.mauve },
    Conditional                                = { link = "Statement" },
    Repeat                                     = { link = "Statement" },
    Label                                      = { fg = c.sapphire },
    Operator                                   = { fg = c.sky },
    Keyword                                    = { link = "Statement" },
    Exception                                  = { link = "Statement" },

    PreProc                                    = { fg = c.pink },
    Include                                    = { link = "Statement" },
    Define                                     = { link = "PreProc" },
    Macro                                      = { link = "Statement" },
    PreCondit                                  = { link = "PreProc" },

    StorageClass                               = { fg = c.yellow },
    Structure                                  = { link = "StorageClass" },
    Special                                    = { fg = c.pink },
    Type                                       = { link = "StorageClass" },
    Typedef                                    = { link = "Type" },
    SpecialChar                                = { link = "Special" },
    Tag                                        = { fg = c.lavender },
    Delimiter                                  = { fg = c.overlay2 },
    Debug                                      = { link = "Special" },

    Underlined                                 = { underline = true },
    Bold                                       = { bold = true },
    Italic                                     = { italic = true },

    Error                                      = { fg = c.red },
    Todo                                       = { bg = c.flamingo, fg = c.base, bold = true },
    DiffAdd                                    = { bg = c.bg_diff_add },
    DiffChange                                 = { bg = c.bg_diff_change },
    DiffDelete                                 = { bg = c.bg_diff_delete },
    DiffText                                   = { bg = c.bg_diff_text },       -- }}}
    -- {{{ Treesitter
    ["@variable"]                              = { fg = c.text },               -- Any variable name that does not have another highlight.
    ["@variable.builtin"]                      = { fg = c.red, italic = true }, -- Variable names that are defined by the languages, like this or self.
    ["@variable.parameter"]                    = { fg = c.maroon },             -- For parameters of a function.
    ["@variable.member"]                       = { fg = c.lavender },           -- For fields.

    ["@constant"]                              = { link = "Constant" },         -- For constants
    ["@constant.builtin"]                      = { link = "Constant" },         -- For constant that are built in the language: nil in Lua.
    ["@constant.macro"]                        = { link = "Macro" },            -- For constants that are defined by macros: NULL in C.

    ["@module"]                                = { fg = c.lavender },           -- For identifiers referring to modules and namespaces.
    ["@label"]                                 = { link = "Label" },            -- For labels: label: in C and :label: in Lua.

    -- Literals
    ["@string"]                                = { link = "String" },                                   -- For strings.
    ["@string.documentation"]                  = { fg = c.teal },                                       -- For strings documenting code (e.g. Python docstrings).
    ["@string.regexp"]                         = { link = "Constant" },                                 -- For regexes.
    ["@string.escape"]                         = { link = "Special" },                                  -- For escape characters within a string.
    ["@string.special"]                        = { link = "Special" },                                  -- other special strings (e.g. dates)
    ["@string.special.path"]                   = { link = "Special" },                                  -- filenames
    ["@string.special.symbol"]                 = { link = "Identifier" },                               -- symbols or atoms
    ["@string.special.url"]                    = { fg = c.rosewater, italic = true, underline = true }, -- urls, links and emails

    ["@character"]                             = { link = "Character" },                                -- character literals
    ["@character.special"]                     = { link = "Special" },                                  -- special characters (e.g. wildcards)

    ["@boolean"]                               = { link = "Constant" },                                 -- For booleans.
    ["@number"]                                = { link = "Constant" },                                 -- For all numbers
    ["@number.float"]                          = { link = "Constant" },                                 -- For floats.

    -- Types
    ["@type"]                                  = { link = "StorageClass" },     -- For types.
    ["@type.builtin"]                          = { link = "Statement" },        -- For builtin types.
    ["@type.definition"]                       = { link = "StorageClass" },     -- type definitions (e.g. `typedef` in C)

    ["@attribute"]                             = { link = "Constant" },         -- attribute annotations (e.g. Python decorators)
    ["@property"]                              = { link = "@variable.member" }, -- Same as TSField.

    -- Functions
    ["@function"]                              = { link = "Function" }, -- For function (calls and definitions).
    ["@function.builtin"]                      = { link = "Function" }, -- For builtin functions: table.insert in Lua.
    ["@function.call"]                         = { link = "Function" }, -- function calls
    ["@function.macro"]                        = { fg = c.teal },       -- For macro defined functions (calls and definitions): each macro_rules in Rust.

    ["@function.method"]                       = { link = "Function" }, -- For method definitions.
    ["@function.method.call"]                  = { link = "Function" }, -- For method calls.

    ["@constructor"]                           = { fg = c.sapphire },   -- For constructor calls and definitions: = { } in Lua, and Java constructors.
    ["@operator"]                              = { link = "Operator" }, -- For any operator: +, but also -> and * in C.

    -- Keywords
    ["@keyword"]                               = { link = "Statement" }, -- For keywords that don't fall in previous categories.
    ["@keyword.modifier"]                      = { link = "Statement" }, -- For keywords modifying other constructs (e.g. `const`, `static`, `public`)
    ["@keyword.type"]                          = { link = "Statement" }, -- For keywords describing composite types (e.g. `struct`, `enum`)
    ["@keyword.coroutine"]                     = { link = "Statement" }, -- For keywords related to coroutines (e.g. `go` in Go, `async/await` in Python)
    ["@keyword.function"]                      = { link = "Statement" }, -- For keywords used to define a function.
    ["@keyword.operator"]                      = { link = "Statement" }, -- For new keyword operator
    ["@keyword.import"]                        = { link = "Include" },   -- For includes: #include in C, use or extern crate in Rust, or require in Lua.
    ["@keyword.repeat"]                        = { link = "Statement" }, -- For keywords related to loops.
    ["@keyword.return"]                        = { link = "Statement" },
    ["@keyword.debug"]                         = { link = "Statement" }, -- For keywords related to debugging
    ["@keyword.exception"]                     = { link = "Statement" }, -- For exception related keywords.

    ["@keyword.conditional"]                   = { link = "Statement" }, -- For keywords related to conditionnals.
    ["@keyword.conditional.ternary"]           = { link = "Operator" },  -- For ternary operators (e.g. `?` / `:`)

    ["@keyword.directive"]                     = { link = "PreProc" },   -- various preprocessor directives & shebangs
    ["@keyword.directive.define"]              = { link = "Define" },    -- preprocessor definition directives
    -- JS & derivative
    ["@keyword.export"]                        = { link = "Operator" },

    -- Punctuation
    ["@punctuation.delimiter"]                 = { link = "Delimiter" }, -- For delimiters (e.g. `;` / `.` / `,`).
    ["@punctuation.bracket"]                   = { link = "Delimiter" }, -- For brackets and parenthesis.
    ["@punctuation.special"]                   = { link = "Special" },   -- For special punctuation that does not fall in the categories before (e.g. `{}` in string interpolation).

    -- Comment
    ["@comment"]                               = { link = "Comment" },
    ["@comment.documentation"]                 = { link = "Comment" }, -- For comments documenting code

    ["@comment.error"]                         = { fg = c.base, bg = c.red },
    ["@comment.warning"]                       = { fg = c.base, bg = c.yellow },
    ["@comment.hint"]                          = { fg = c.base, bg = c.blue },
    ["@comment.todo"]                          = { fg = c.base, bg = c.flamingo },
    ["@comment.note"]                          = { fg = c.base, bg = c.rosewater },

    -- Markup
    ["@markup"]                                = { fg = c.text },                                       -- For strings considerated text in a markup language.
    ["@markup.strong"]                         = { fg = c.maroon, bold = true },                        -- bold
    ["@markup.italic"]                         = { fg = c.maroon, italic = true },                      -- italic
    ["@markup.strikethrough"]                  = { fg = c.text, strikethrough = true },                 -- strikethrough text
    ["@markup.underline"]                      = { link = "Underlined" },                               -- underlined text

    ["@markup.heading"]                        = { fg = c.blue, bold = true },                          -- titles like: # Example

    ["@markup.math"]                           = { fg = c.blue },                                       -- math environments (e.g. `$ ... $` in LaTeX)
    ["@markup.quote"]                          = { fg = c.maroon, bold = true },                        -- block quotes
    ["@markup.environment"]                    = { fg = c.pink },                                       -- text environments of markup languages
    ["@markup.environment.name"]               = { fg = c.blue },                                       -- text indicating the type of an environment

    ["@markup.link"]                           = { link = "Tag" },                                      -- text references, footnotes, citations, etc.
    ["@markup.link.label"]                     = { link = "Label" },                                    -- link, reference descriptions
    ["@markup.link.url"]                       = { fg = c.rosewater, italic = true, underline = true }, -- urls, links and emails

    ["@markup.raw"]                            = { fg = c.teal },                                       -- used for inline code in markdown and for doc in python (""")

    ["@markup.list"]                           = { link = "Special" },
    ["@markup.list.checked"]                   = { fg = c.green },    -- todo notes
    ["@markup.list.unchecked"]                 = { fg = c.overlay1 }, -- todo notes

    -- Diff
    ["@diff.plus"]                             = { link = "diffAdded" },   -- added text (for diff files)
    ["@diff.minus"]                            = { link = "diffRemoved" }, -- deleted text (for diff files)
    ["@diff.delta"]                            = { link = "diffChanged" }, -- deleted text (for diff files)

    -- Tags
    ["@tag"]                                   = { fg = c.mauve },               -- Tags like html tag names.
    ["@tag.attribute"]                         = { fg = c.teal, italic = true }, -- Tags like html tag names.
    ["@tag.delimiter"]                         = { fg = c.sky },                 -- Tag delimiter like < > /

    -- Misc
    ["@error"]                                 = { link = "Error" },

    -- lua
    ["@constructor.lua"]                       = { fg = c.flamingo }, -- For constructor calls and definitions: = { } in Lua.

    -- C/CPP
    ["@property.cpp"]                          = { link = "@variable" },
    ["@type.builtin.c"]                        = { link = "StorageClass" },
    ["@type.builtin.cpp"]                      = { link = "StorageClass" },

    -- Python
    ["@module.python"]                         = { link = "StorageClass" }, -- For identifiers referring to modules and namespaces.
    ["@constructor.python"]                    = { link = "StorageClass" }, -- For constructor calls and definitions: = { } in Lua, and Java constructors.

    -- gitcommit
    ["@comment.warning.gitcommit"]             = { fg = c.yellow },

    -- gitignore
    ["@string.special.path.gitignore"]         = { fg = c.text }, -- }}}
    -- {{{ Semantic Tokens
    ["@lsp.type.boolean"]                      = { link = "Constant" },
    ["@lsp.type.builtinType"]                  = { link = "Type" },
    ["@lsp.type.comment"]                      = { link = "Comment" },
    ["@lsp.type.class"]                        = { link = "StorageClass" },
    ["@lsp.type.enum"]                         = { link = "StorageClass" },
    ["@lsp.type.decorator"]                    = {},
    ["@lsp.type.enumMember"]                   = { link = "Constant" },
    ["@lsp.type.escapeSequence"]               = { link = "Special" },
    ["@lsp.type.function"]                     = { link = "Function" },
    ["@lsp.type.formatSpecifier"]              = { link = "Special" },
    ["@lsp.type.interface"]                    = { link = "Identifier" },
    ["@lsp.type.keyword"]                      = { link = "Statement" },
    ["@lsp.type.method"]                       = {},
    ["@lsp.type.namespace"]                    = { link = "@module" },
    ["@lsp.type.number"]                       = { link = "Constant" },
    ["@lsp.type.operator"]                     = { link = "Operator" },
    ["@lsp.type.parameter"]                    = { link = "@variable.parameter" },
    ["@lsp.type.property"]                     = { link = "@variable.member" },
    ["@lsp.type.selfKeyword"]                  = { link = "@variable.builtin" },
    ["@lsp.type.typeAlias"]                    = { link = "@type.definition" },
    ["@lsp.type.unresolvedReference"]          = { link = "Error" },
    ["@lsp.type.variable"]                     = {},
    ["@lsp.typemod.class.defaultLibrary"]      = { link = "Statement" },
    ["@lsp.typemod.enum.defaultLibrary"]       = { link = "StorageClass" },
    ["@lsp.typemod.enumMember.defaultLibrary"] = { link = "Constant" },
    ["@lsp.typemod.function.defaultLibrary"]   = {},
    ["@lsp.typemod.keyword.async"]             = { link = "@keyword.coroutine" },
    ["@lsp.typemod.macro.defaultLibrary"]      = { link = "Constant" },
    ["@lsp.typemod.method.defaultLibrary"]     = { link = "Constant" },
    ["@lsp.typemod.operator.injected"]         = { link = "Operator" },
    ["@lsp.typemod.string.injected"]           = { link = "String" },
    ["@lsp.typemod.type.defaultLibrary"]       = { link = "Statement" },
    ["@lsp.typemod.variable.defaultLibrary"]   = { link = "@variable.builtin" },
    ["@lsp.typemod.variable.injected"]         = { link = "@variable" },

    -- Python
    ["@lsp.type.namespace.python"]             = { link = "StorageClass" }, -- }}}
    -- {{{ Neotree
    NeoTreeDirectoryName                       = { link = "Directory" },
    NeoTreeDirectoryIcon                       = { link = "Directory" },
    NeoTreeNormal                              = { fg = c.text, bg = active_bg },
    NeoTreeNormalNC                            = { fg = c.text, bg = active_bg },
    NeoTreeExpander                            = { fg = c.overlay0 },
    NeoTreeIndentMarker                        = { fg = c.overlay0 },
    NeoTreeRootName                            = { fg = c.blue, bold = true },
    NeoTreeSymbolicLinkTarget                  = { fg = c.pink },
    NeoTreeModified                            = { fg = c.peach },

    NeoTreeGitAdded                            = { fg = c.green },
    NeoTreeGitConflict                         = { fg = c.red },
    NeoTreeGitDeleted                          = { fg = c.red },
    NeoTreeGitModified                         = { fg = c.yellow },
    NeoTreeGitIgnored                          = { fg = c.overlay0 },
    NeoTreeGitUnstaged                         = { fg = c.red },
    NeoTreeGitUntracked                        = { fg = c.mauve },
    NeoTreeGitStaged                           = { fg = c.green },

    NeoTreeFloatBorder                         = { link = "FloatBorder" },
    NeoTreeFloatTitle                          = { link = "FloatTitle" },
    NeoTreeTitleBar                            = { fg = c.mantle, bg = c.blue },

    NeoTreeFileNameOpened                      = { fg = c.pink },
    NeoTreeDimText                             = { fg = c.overlay1 },
    NeoTreeFilterTerm                          = { fg = c.green, bold = true },
    NeoTreeTabActive                           = { bg = active_bg, fg = c.lavender, bold = true },
    NeoTreeTabInactive                         = { bg = inactive_bg, fg = c.overlay0 },
    NeoTreeTabSeparatorActive                  = { fg = active_bg, bg = active_bg },
    NeoTreeTabSeparatorInactive                = { fg = inactive_bg, bg = inactive_bg },
    NeoTreeVertSplit                           = { fg = c.base, bg = inactive_bg },
    NeoTreeWinSeparator                        = { fg = t and c.surface1 or c.base, bg = inactive_bg },
    NeoTreeStatusLineNC                        = { fg = c.mantle, bg = c.mantle }, -- }}}
    -- {{{ Blink
    BlinkCmpMenuBorder                         = { fg = c.surface2, bg = c.mantle },
    linkCmpDocBorder                           = { link = "FloatBorder" },
    BlinkCmpLabel                              = { fg = c.overlay2 },
    BlinkCmpLabelDeprecated                    = { fg = c.overlay0, strikethrough = true },
    BlinkCmpKind                               = { fg = c.blue },
    BlinkCmpMenu                               = { link = "Pmenu" },
    BlinkCmpDoc                                = { link = "NormalFloat" },
    BlinkCmpLabelMatch                         = { fg = c.text, bold = true },
    BlinkCmpMenuSelection                      = { bg = c.surface1, bold = true },
    BlinkCmpScrollBarGutter                    = { bg = c.surface1 },
    BlinkCmpScrollBarThumb                     = { bg = c.overlay0 },
    BlinkCmpLabelDescription                   = { fg = c.overlay0 },
    BlinkCmpLabelDetail                        = { fg = c.overlay0 },

    BlinkCmpKindText                           = { fg = c.green },
    BlinkCmpKindMethod                         = { fg = c.blue },
    BlinkCmpKindFunction                       = { fg = c.blue },
    BlinkCmpKindConstructor                    = { fg = c.blue },
    BlinkCmpKindField                          = { fg = c.green },
    BlinkCmpKindVariable                       = { fg = c.flamingo },
    BlinkCmpKindClass                          = { fg = c.yellow },
    BlinkCmpKindInterface                      = { fg = c.yellow },
    BlinkCmpKindModule                         = { fg = c.blue },
    BlinkCmpKindProperty                       = { fg = c.blue },
    BlinkCmpKindUnit                           = { fg = c.green },
    BlinkCmpKindValue                          = { fg = c.peach },
    BlinkCmpKindEnum                           = { fg = c.yellow },
    BlinkCmpKindKeyword                        = { fg = c.mauve },
    BlinkCmpKindSnippet                        = { fg = c.flamingo },
    BlinkCmpKindColor                          = { fg = c.red },
    BlinkCmpKindFile                           = { fg = c.blue },
    BlinkCmpKindReference                      = { fg = c.red },
    BlinkCmpKindFolder                         = { fg = c.blue },
    BlinkCmpKindEnumMember                     = { fg = c.teal },
    BlinkCmpKindConstant                       = { fg = c.peach },
    BlinkCmpKindStruct                         = { fg = c.blue },
    BlinkCmpKindEvent                          = { fg = c.blue },
    BlinkCmpKindOperator                       = { fg = c.sky },
    BlinkCmpKindTypeParameter                  = { fg = c.maroon },
    BlinkCmpKindCopilot                        = { fg = c.teal }, -- }}}
  }

  return h
end

return M
