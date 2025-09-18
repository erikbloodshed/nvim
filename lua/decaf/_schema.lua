local M = {}

function M.get(c, o)
  local t = o.transparency
  local t_co = t and c.none
  local s_transp = t and c.surface1
  local f_transp = (o.float.transparent and vim.o.winblend == 0) and c.none
  local p_transp = (t and vim.o.pumblend == 0) and c.none
  local active_bg = t_co or c.mantle
  local inactive_bg = t_co or c.base
  local error = c.red
  local warn = c.yellow
  local info = c.sky
  local hint = c.teal
  local ok = c.green

  return {
    -- {{{ Editor
    ColorColumn = { bg = c.surface0 },
    Conceal = { fg = c.overlay1 },
    Cursor = { fg = c.base, bg = c.rosewater },
    lCursor = { link = "Cursor" },
    CursorIM = { link = "Cursor" },
    CursorColumn = { bg = c.mantle },
    CursorLine = { bg = c.bg_line },
    Directory = { fg = c.blue },
    EndOfBuffer = { fg = c.base },
    ErrorMsg = { fg = c.red, bold = true, italic = true },
    VertSplit = { fg = s_transp or c.crust },
    Folded = { fg = c.blue, bg = t_co or c.surface1 },
    FoldColumn = { fg = c.overlay0 },
    SignColumn = { fg = c.surface1 },
    SignColumnSB = { bg = c.crust, fg = c.surface1 },
    Substitute = { bg = c.surface1, fg = c.pink },
    LineNr = { fg = c.surface1 },
    CursorLineNr = { fg = c.lavender },
    MatchParen = { fg = c.peach, bg = c.surface1, bold = true },
    ModeMsg = { fg = c.text, bold = true },
    MsgSeparator = {},
    MoreMsg = { fg = c.blue },
    NonText = { fg = c.overlay0 },
    Normal = { fg = c.text, bg = t_co or c.base },
    NormalNC = { fg = c.text, bg = t_co or c.dim },
    NormalSB = { fg = c.text, bg = c.crust },
    NormalFloat = { fg = c.text, bg = f_transp or c.base },
    FloatBorder = { fg = c.surface1, bg = f_transp or c.base },
    FloatTitle = o.float.solid and { fg = c.crust, bg = c.lavender } or { fg = c.subtext0, bg = f_transp or c.mantle },
    FloatShadow = { fg = f_transp or c.overlay0 },
    Pmenu = { bg = p_transp or c.mantle, fg = c.overlay2 },
    PmenuSel = { bg = c.surface0, bold = true },
    PmenuSbar = { bg = c.surface0 },
    PmenuThumb = { bg = c.overlay0 },
    PmenuExtra = { fg = c.overlay0 },
    PmenuExtraSel = { fg = c.overlay0, bold = true },
    Question = { fg = c.blue },
    QuickFixLine = { bg = c.surface1, bold = true },
    Search = { bg = c.bg_search, fg = c.text },
    IncSearch = { bg = c.bg_incsearch, fg = c.mantle },
    CurSearch = { bg = c.red, fg = c.mantle },
    SpecialKey = { link = "NonText" },
    SpellBad = { sp = c.red, undercurl = true },
    SpellCap = { sp = c.yellow, undercurl = true },
    SpellLocal = { sp = c.blue, undercurl = true },
    SpellRare = { sp = c.green, undercurl = true },
    StatusLine = { fg = c.text, bg = t_co or c.mantle },
    StatusLineNC = { fg = c.surface1, bg = t_co or c.mantle },
    StatusLineNormal = { bg = c.blue, fg = c.crust, bold = true },
    StatusLineInsert = { bg = c.green, fg = c.crust, bold = true },
    StatusLineVisual = { bg = c.mauve, fg = c.crust, bold = true },
    StatusLineCommand = { bg = c.yellow, fg = c.crust, bold = true },
    StatusLineReplace = { bg = c.maroon, fg = c.crust, bold = true },
    StatusLineTerminal = { bg = c.green, fg = c.crust, bold = true },
    StatusLineGit = { fg = c.peach },
    StatusLineModified = { fg = c.yellow },
    StatusLineFile = { fg = c.text },
    StatusLineDiagError = { link = "DiagnosticError" },
    StatusLineDiagWarn = { link = "DiagnosticWarn" },
    StatusLineDiagHint = { link = "DiagnosticHint" },
    StatusLineDiagInfo = { link = "DiagnosticInfo" },
    StatusLineLsp = { fg = c.green },
    StatusLineLabel = { fg = c.subtext0 },
    StatusLineValue = { link = "StatusLineGit" },
    StatusLineSeparator = { fg = c.surface0 },

    TabLine = { bg = c.crust, fg = c.overlay0 },
    TabLineFill = { bg = t_co or c.mantle },
    TabLineSel = { link = "Normal" },
    TermCursor = { fg = c.base, bg = c.rosewater },
    TermCursorNC = { fg = c.base, bg = c.overlay2 },
    Title = { fg = c.blue, bold = true },
    Visual = { bg = c.surface1, bold = true },
    VisualNOS = { link = "Visual" },
    WarningMsg = { fg = c.yellow },
    Whitespace = { fg = c.surface1 },
    WildMenu = { bg = c.overlay0 },
    WinBar = { fg = c.rosewater },
    WinBarNC = { link = "WinBar" },
    WinSeparator = { fg = s_transp or c.crust },
    -- }}}
    -- {{{ Native LSP
    DiagnosticVirtualTextError = { bg = t_co or c.bg_dvt_error, fg = error, italic = true },
    DiagnosticVirtualTextWarn = { bg = t_co or c.bg_dvt_warn, fg = warn, italic = true },
    DiagnosticVirtualTextInfo = { bg = t_co or c.bg_dvt_info, fg = info, italic = true },
    DiagnosticVirtualTextHint = { bg = t_co or c.bg_dvt_hint, fg = hint, italic = true },
    DiagnosticVirtualTextOk = { bg = t_co or c.bg_dvt_ok, fg = ok, italic = true },

    DiagnosticError = { fg = error },
    DiagnosticWarn = { fg = warn },
    DiagnosticInfo = { fg = info },
    DiagnosticHint = { fg = hint },
    DiagnosticOk = { fg = ok },

    DiagnosticUnderlineError = { undercurl = true, sp = error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = warn },
    DiagnosticUnderlineInfo = { undercurl = true, sp = info },
    DiagnosticUnderlineHint = { undercurl = true, sp = hint },
    DiagnosticUnderlineOk = { undercurl = true, sp = ok },

    DiagnosticFloatingError = { link = "DiagnosticError" },
    DiagnosticFloatingWarn = { link = "DiagnosticWarn" },
    DiagnosticFloatingInfo = { link = "DiagnosticInfo" },
    DiagnosticFloatingHint = { link = "DiagnosticHint" },
    DiagnosticFloatingOk = { link = "DiagnosticOk" },

    DiagnosticSignError = { link = "DiagnosticError" },
    DiagnosticSignWarn = { link = "DiagnosticWarn" },
    DiagnosticSignInfo = { link = "DiagnosticInfo" },
    DiagnosticSignHint = { link = "DiagnosticHint" },
    DiagnosticSignOk = { link = "DiagnosticOk" },

    LspDiagnosticsDefaultError = { link = "DiagnosticError" },
    LspDiagnosticsDefaultWarning = { link = "DiagnosticWarn" },
    LspDiagnosticsDefaultInformation = { link = "DiagnosticInfo" },
    LspDiagnosticsDefaultHint = { link = "DiagnosticHint" },

    LspDiagnosticsError = { link = "DiagnosticError" },
    LspDiagnosticsWarning = { link = "DiagnosticWarn" },
    LspDiagnosticsInformation = { link = "DiagnosticInfo" },
    LspDiagnosticsHint = { link = "DiagnosticHint" },

    LspDiagnosticsVirtualTextError = { link = "DiagnosticError" },
    LspDiagnosticsVirtualTextWarning = { link = "DiagnosticWarn" },
    LspDiagnosticsVirtualTextInformation = { link = "DiagnosticInfo" },
    LspDiagnosticsVirtualTextHint = { link = "DiagnosticHint" },

    LspDiagnosticsUnderlineError = { link = "DiagnosticUnderlineError" },
    LspDiagnosticsUnderlineWarning = { link = "DiagnosticUnderlineWarn" },
    LspDiagnosticsUnderlineInformation = { link = "DiagnosticUnderlineInfo" },
    LspDiagnosticsUnderlineHint = { link = "DiagnosticUnderlineHint" },

    LspSignatureActiveParameter = { bg = c.surface0, bold = true },
    LspCodeLens = { fg = c.overlay0 },
    LspCodeLensSeparator = { link = "LspCodeLens" },
    LspInlayHint = { fg = c.overlay0, bg = t_co or c.bg_line },
    LspInfoBorder = { link = "FloatBorder" },
    LspReferenceText = { bg = c.surface1 },
    LspReferenceRead = { link = "LspReferenceText" },
    LspReferenceWrite = { link = "LspReferenceText" }, -- }}}
    -- {{{ Syntax
    Comment = { fg = c.overlay2, italic = true },
    SpecialComment = { link = "Special" },
    Constant = { fg = c.peach },
    String = { fg = c.green },
    Character = { fg = c.teal },
    Number = { link = "Constant" },
    Float = { link = "Constant" },
    Boolean = { link = "Constant" },
    Identifier = { fg = c.flamingo },
    Function = { fg = c.blue },
    Statement = { fg = c.mauve },
    Conditional = { link = "Statement" },
    Repeat = { link = "Statement" },
    Label = { fg = c.sapphire },
    Operator = { fg = c.sky },
    Keyword = { link = "Statement" },
    Exception = { link = "Statement" },
    PreProc = { fg = c.pink },
    Include = { link = "Statement" },
    Define = { link = "PreProc" },
    Macro = { link = "Statement" },
    PreCondit = { link = "PreProc" },
    StorageClass = { fg = c.yellow },
    Structure = { link = "StorageClass" },
    Special = { fg = c.pink },
    Type = { link = "StorageClass" },
    Typedef = { link = "Type" },
    SpecialChar = { link = "Special" },
    Tag = { fg = c.lavender },
    Delimiter = { fg = c.overlay2 },
    Debug = { link = "Special" },
    Underlined = { underline = true },
    Bold = { bold = true },
    Italic = { italic = true },
    Error = { fg = error },
    Todo = { bg = c.flamingo, fg = c.base, bold = true },
    DiffAdd = { bg = c.bg_diff_add },
    DiffChange = { bg = c.bg_diff_change },
    DiffDelete = { bg = c.bg_diff_delete },
    DiffText = { bg = c.bg_diff_text },
    -- }}}
    -- {{{ Treesitter
    ["@variable"] = { fg = c.text },
    ["@variable.builtin"] = { fg = c.red },
    ["@variable.parameter"] = { fg = c.maroon },
    ["@variable.member"] = { fg = c.lavender },

    ["@constant"] = { link = "Constant" },
    ["@constant.builtin"] = { link = "Constant" },
    ["@constant.macro"] = { link = "Macro" },

    ["@module"] = { fg = c.lavender },
    ["@label"] = { link = "Label" },

    ["@string"] = { link = "String" },
    ["@string.documentation"] = { link = "String" },
    ["@string.regexp"] = { link = "Constant" },
    ["@string.escape"] = { link = "Special" },
    ["@string.special"] = { link = "Special" },
    ["@string.special.path"] = { link = "Special" },
    ["@string.special.symbol"] = { link = "Identifier" },
    ["@string.special.url"] = { fg = c.rosewater, italic = true, underline = true },

    ["@character"] = { link = "Character" },
    ["@character.special"] = { link = "Special" },

    ["@boolean"] = { link = "Constant" },
    ["@number"] = { link = "Constant" },
    ["@number.float"] = { link = "Constant" },

    -- Types
    ["@type"] = { link = "StorageClass" },
    ["@type.builtin"] = { link = "Operator" },
    ["@type.definition"] = { link = "StorageClass" },

    ["@attribute"] = { link = "Special" },
    ["@property"] = { link = "@variable.member" },

    -- Functions
    ["@function"] = { link = "Function" },
    ["@function.builtin"] = { link = "Operator" },
    ["@function.call"] = { link = "Function" },
    ["@function.macro"] = { fg = c.teal },

    ["@function.method"] = { link = "Function" },
    ["@function.method.call"] = { link = "Function" },

    ["@constructor"] = {},
    ["@operator"] = { link = "Operator" },

    ["@keyword"] = { link = "Statement" },
    ["@keyword.modifier"] = { link = "Statement" },
    ["@keyword.type"] = { link = "Statement" },
    ["@keyword.coroutine"] = { link = "Statement" },
    ["@keyword.function"] = { link = "Statement" },
    ["@keyword.operator"] = { link = "Operator" },
    ["@keyword.import"] = { link = "Include" },
    ["@keyword.repeat"] = { link = "Statement" },
    ["@keyword.return"] = { link = "Statement" },
    ["@keyword.debug"] = { link = "Statement" },
    ["@keyword.exception"] = { link = "Statement" },

    ["@keyword.conditional"] = { link = "Statement" },
    ["@keyword.conditional.ternary"] = { link = "Operator" },

    ["@keyword.directive"] = { link = "PreProc" },
    ["@keyword.directive.define"] = { link = "Define" },
    ["@keyword.export"] = { link = "Operator" },

    ["@punctuation.delimiter"] = { link = "Delimiter" },
    ["@punctuation.bracket"] = { link = "Delimiter" },
    ["@punctuation.special"] = { link = "Special" },

    ["@comment"] = { link = "Comment" },
    ["@comment.documentation"] = { link = "Comment" },

    ["@comment.error"] = { fg = c.base, bg = c.red },
    ["@comment.warning"] = { fg = c.base, bg = c.yellow },
    ["@comment.hint"] = { fg = c.base, bg = c.blue },
    ["@comment.todo"] = { fg = c.base, bg = c.flamingo },
    ["@comment.note"] = { fg = c.base, bg = c.rosewater },

    ["@markup"] = { fg = c.text },
    ["@markup.strong"] = { fg = c.maroon, bold = true },
    ["@markup.italic"] = { fg = c.maroon, italic = true },
    ["@markup.strikethrough"] = { fg = c.text, strikethrough = true },
    ["@markup.underline"] = { link = "Underlined" },

    ["@markup.heading"] = { fg = c.blue, bold = true },

    ["@markup.math"] = { fg = c.blue },
    ["@markup.quote"] = { fg = c.maroon, bold = true },
    ["@markup.environment"] = { fg = c.pink },
    ["@markup.environment.name"] = { fg = c.blue },

    ["@markup.link"] = { link = "Tag" },
    ["@markup.link.label"] = { link = "Label" },
    ["@markup.link.url"] = { fg = c.rosewater, italic = true, underline = true },

    ["@markup.raw"] = { fg = c.teal },

    ["@markup.list"] = { link = "Special" },
    ["@markup.list.checked"] = { fg = c.green },
    ["@markup.list.unchecked"] = { fg = c.overlay1 },

    -- Diff
    ["@diff.plus"] = { link = "diffAdded" },
    ["@diff.minus"] = { link = "diffRemoved" },
    ["@diff.delta"] = { link = "diffChanged" },

    -- Tags
    ["@tag"] = { fg = c.mauve },
    ["@tag.attribute"] = { fg = c.teal, italic = true },
    ["@tag.delimiter"] = { fg = c.sky },

    -- Misc
    ["@error"] = { link = "Error" },

    -- lua
    ["@constructor.lua"] = { fg = c.flamingo },

    -- C/CPP
    ["@property.cpp"] = { link = "@variable" },
    ["@type.builtin.c"] = { link = "StorageClass" },
    ["@type.builtin.cpp"] = { link = "StorageClass" },

    -- Python
    ["@module.python"] = { link = "StorageClass" },
    ["@constructor.python"] = { link = "StorageClass" },

    -- gitcommit
    ["@comment.warning.gitcommit"] = { fg = c.yellow },

    -- gitignore
    ["@string.special.path.gitignore"] = { fg = c.text }, -- }}}
    -- {{{ Semantic Tokens
    ["@lsp.type.boolean"] = { link = "Constant" },
    ["@lsp.type.builtinType"] = { link = "Type" },
    ["@lsp.type.comment"] = { link = "Comment" },
    ["@lsp.type.class"] = {},
    ["@lsp.type.enum"] = { link = "StorageClass" },
    ["@lsp.type.decorator"] = {},
    ["@lsp.type.enumMember"] = { link = "Constant" },
    ["@lsp.type.escapeSequence"] = { link = "Special" },
    ["@lsp.type.function"] = {},
    ["@lsp.type.formatSpecifier"] = { link = "Special" },
    ["@lsp.type.interface"] = { link = "Identifier" },
    ["@lsp.type.keyword"] = { link = "Statement" },
    ["@lsp.type.method"] = {},
    ["@lsp.type.namespace"] = { link = "@module" },
    ["@lsp.type.number"] = { link = "Constant" },
    ["@lsp.type.operator"] = { link = "Operator" },
    ["@lsp.type.parameter"] = { link = "@variable.parameter" },
    ["@lsp.type.property"] = { link = "@variable.member" },
    ["@lsp.type.selfKeyword"] = { link = "@variable.builtin" },
    ["@lsp.type.selfParameter"] = { link = "@variable.builtin" },
    ["@lsp.type.typeAlias"] = { link = "@type.definition" },
    ["@lsp.type.unresolvedReference"] = { link = "Error" },
    ["@lsp.type.variable"] = {},
    -- ["@lsp.typemod.class.defaultLibrary"] = { link = "Statement" },
    ["@lsp.typemod.enum.defaultLibrary"] = { link = "StorageClass" },
    ["@lsp.typemod.enumMember.defaultLibrary"] = { link = "Constant" },
    ["@lsp.typemod.function.defaultLibrary"] = {},
    ["@lsp.typemod.keyword.async"] = { link = "@keyword.coroutine" },
    ["@lsp.typemod.macro.defaultLibrary"] = { link = "Constant" },
    ["@lsp.typemod.method.defaultLibrary"] = { link = "Constant" },
    ["@lsp.typemod.operator.injected"] = { link = "Operator" },
    ["@lsp.typemod.string.injected"] = { link = "String" },
    ["@lsp.typemod.type.defaultLibrary"] = { link = "Statement" },
    ["@lsp.typemod.variable.defaultLibrary"] = {},
    ["@lsp.typemod.variable.injected"] = { link = "@variable" },

    ["@lsp.typemod.variable.readonly.cpp"] = { link = "Constant" },
    ["@lsp.type.namespace.python"] = { link = "StorageClass" }, -- }}}
    -- {{{ Neotree
    NeoTreeDirectoryName = { link = "Directory" },
    NeoTreeDirectoryIcon = { link = "Directory" },
    NeoTreeNormal = { fg = c.text, bg = active_bg },
    NeoTreeNormalNC = { fg = c.text, bg = active_bg },
    NeoTreeExpander = { fg = c.overlay0 },
    NeoTreeIndentMarker = { fg = c.overlay0 },
    NeoTreeRootName = { fg = c.blue, bold = true },
    NeoTreeSymbolicLinkTarget = { fg = c.pink },
    NeoTreeModified = { fg = c.peach },

    NeoTreeGitAdded = { fg = c.green },
    NeoTreeGitConflict = { fg = c.red },
    NeoTreeGitDeleted = { fg = c.red },
    NeoTreeGitModified = { fg = c.yellow },
    NeoTreeGitIgnored = { fg = c.overlay0 },
    NeoTreeGitUnstaged = { fg = c.red },
    NeoTreeGitUntracked = { fg = c.mauve },
    NeoTreeGitStaged = { fg = c.green },

    NeoTreeFloatBorder = { link = "FloatBorder" },
    NeoTreeFloatTitle = { link = "FloatTitle" },
    NeoTreeTitleBar = { fg = c.mantle, bg = c.blue },

    NeoTreeFileNameOpened = { fg = c.pink },
    NeoTreeDimText = { fg = c.overlay1 },
    NeoTreeFilterTerm = { fg = c.green, bold = true },
    NeoTreeTabActive = { bg = active_bg, fg = c.lavender, bold = true },
    NeoTreeTabInactive = { bg = inactive_bg, fg = c.overlay0 },
    NeoTreeTabSeparatorActive = { fg = active_bg, bg = active_bg },
    NeoTreeTabSeparatorInactive = { fg = inactive_bg, bg = inactive_bg },
    NeoTreeVertSplit = { fg = c.base, bg = inactive_bg },
    NeoTreeWinSeparator = { fg = t and c.surface1 or c.base, bg = inactive_bg },
    NeoTreeStatusLineNC = { fg = c.mantle, bg = c.mantle }, -- }}}
    -- {{{ Blink
    BlinkCmpMenuBorder = { fg = c.surface2, bg = c.mantle },
    linkCmpDocBorder = { link = "FloatBorder" },
    BlinkCmpLabel = { fg = c.overlay2 },
    BlinkCmpLabelDeprecated = { fg = c.overlay0, strikethrough = true },
    BlinkCmpKind = { fg = c.blue },
    BlinkCmpMenu = { link = "Pmenu" },
    BlinkCmpDoc = { link = "NormalFloat" },
    BlinkCmpLabelMatch = { fg = c.text, bold = true },
    BlinkCmpMenuSelection = { bg = c.surface1, bold = true },
    BlinkCmpScrollBarGutter = { bg = c.surface1 },
    BlinkCmpScrollBarThumb = { bg = c.overlay0 },
    BlinkCmpLabelDescription = { fg = c.overlay0 },
    BlinkCmpLabelDetail = { fg = c.overlay0 },

    BlinkCmpKindText = { fg = c.green },
    BlinkCmpKindMethod = { fg = c.blue },
    BlinkCmpKindFunction = { fg = c.blue },
    BlinkCmpKindConstructor = { fg = c.blue },
    BlinkCmpKindField = { fg = c.green },
    BlinkCmpKindVariable = { fg = c.flamingo },
    BlinkCmpKindClass = { fg = c.yellow },
    BlinkCmpKindInterface = { fg = c.yellow },
    BlinkCmpKindModule = { fg = c.blue },
    BlinkCmpKindProperty = { fg = c.blue },
    BlinkCmpKindUnit = { fg = c.green },
    BlinkCmpKindValue = { fg = c.peach },
    BlinkCmpKindEnum = { fg = c.yellow },
    BlinkCmpKindKeyword = { fg = c.mauve },
    BlinkCmpKindSnippet = { fg = c.flamingo },
    BlinkCmpKindColor = { fg = c.red },
    BlinkCmpKindFile = { fg = c.blue },
    BlinkCmpKindReference = { fg = c.red },
    BlinkCmpKindFolder = { fg = c.blue },
    BlinkCmpKindEnumMember = { fg = c.teal },
    BlinkCmpKindConstant = { fg = c.peach },
    BlinkCmpKindStruct = { fg = c.blue },
    BlinkCmpKindEvent = { fg = c.blue },
    BlinkCmpKindOperator = { fg = c.sky },
    BlinkCmpKindTypeParameter = { fg = c.maroon },
    BlinkCmpKindCopilot = { fg = c.teal }, -- }}}
    -- {{{ Bufswitch
    BufSwitchSelected = { link = "PmenuSel" },
    BufSwitchInactive = { bg = c.mantle, fg = c.overlay0, },
    BufSwitchSeparator = { fg = c.surface1 },
    BufSwitchFill = { bg = c.mantle },
  }
end

return M
