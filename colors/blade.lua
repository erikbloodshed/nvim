-- Blade colorscheme
-- Localize the API for performance
local hl = vim.api.nvim_set_hl
local hl_token = vim.lsp.semantic_tokens.highlight_token
local g = vim.g
local o = vim.o
local cmd = vim.cmd

-- Clear existing highlights to prevent conflicts
cmd.highlight("clear")

if vim.fn.exists("syntax_on") then
  cmd.syntax("reset")
end

-- Set terminal colors and colorscheme name
o.termguicolors = true
g.colors_name = "blade"

-- Blade color palette
local c = {
  clear = "none",
  background = "#282a36",
  foreground = "#f8f8f2",
  selection = "#44475a",
  comment = "#6272a4",
  red = "#ff5555",
  orange = "#ffb86c",
  yellow = "#f1fa8c",
  green = "#50fa7b",
  purple = "#bd93f9",
  cyan = "#8be9fd",
  pink = "#ff79c6",
}

-- Terminal colors (Ayu Dark 16-color palette)
-- g.terminal_color_0 = c.bg0
-- g.terminal_color_1 = c.red
-- g.terminal_color_2 = c.green
-- g.terminal_color_3 = c.yellow
-- g.terminal_color_4 = c.blue
-- g.terminal_color_5 = c.purple
-- g.terminal_color_6 = c.cyan
-- g.terminal_color_7 = c.fg
-- g.terminal_color_8 = c.grey
-- g.terminal_color_9 = c.red
-- g.terminal_color_10 = c.green
-- g.terminal_color_11 = c.yellow
-- g.terminal_color_12 = c.blue
-- g.terminal_color_13 = c.purple
-- g.terminal_color_14 = c.cyan
-- g.terminal_color_15 = c.light_grey

local highlights = {
  -- Base highlights
  ColorColumn = {},
  Cursor = {},
  CursorLine = { bg = c.selection },
  CursorColumn = {},
  CursorLineNr = {},
  Directory = {},
  ErrorMsg = {},
  FloatBorder = {},
  FloatTitle = {},
  FoldColumn = {},
  Folded = {},
  Search = {},
  IncSearch = {},
  LineNr = {},
  ModeMsg = {},
  MoreMsg = {},
  NonText = {},
  Normal = { fg = c.foreground, bg = c.none },
  NormalFloat = {},
  Pmenu = {},
  PmenuSbar = {},
  PmenuSel = {},
  PmenuThumb = {},
  Question = {},
  SignColumn = {},
  SpecialKey = {},
  StatusLine = {},
  StatusLineNC = {},
  TabLine = {},
  TabLineFill = {},
  TabLineSel = {},
  Title = {},
  VertSplit = {},
  WinSeparator = {},
  Visual = {},
  VisualNOS = {},
  WarningMsg = {},
  Whitespace = {},
  EndOfBuffer = {},
  WildMenu = {},
  QuickFixLine = {},
  MatchParen = {},

  -- Syntax highlighting
  Boolean = {},
  Character = {},
  Comment = { fg = c.comment },
  Conditional = {},
  Constant = {},
  Debug = {},
  Define = {},
  Delimiter = {},
  Error = {},
  Exception = {},
  Float = {},
  Function = {},
  Identifier = {},
  Ignore = {},
  Include = {},
  Keyword = {},
  Label = {},
  Macro = {},
  Number = {},
  Operator = {},
  PreCondit = {},
  PreProc = {},
  Repeat = {},
  Special = {},
  SpecialChar = {},
  SpecialComment = {},
  Statement = {},
  StorageClass = {},
  String = {},
  Structure = {},
  Tag = {},
  Todo = {},
  Type = {},
  Typedef = {},
  Underlined = {},

  -- Diagnostic highlights (Ayu Dark style)
  DiagnosticError = {},
  DiagnosticWarn = {},
  DiagnosticInfo = {},
  DiagnosticHint = {},
  DiagnosticVirtualTextError = {},
  DiagnosticVirtualTextWarn = {},
  DiagnosticVirtualTextInfo = {},
  DiagnosticVirtualTextHint = {},
  DiagnosticUnderlineError = {},
  DiagnosticUnderlineWarn = {},
  DiagnosticUnderlineInfo = {},
  DiagnosticUnderlineHint = {},

  -- Git highlights (Ayu Dark style)
  DiffAdd = {},
  DiffChange = {},
  DiffDelete = {},
  DiffText = {},
  GitSignsAdd = {},
  GitSignsChange = {},
  GitSignsDelete = {},

  -- Treesitter highlights (Ayu Dark mappings)
  ["@annotation"] = {},
  ["@attribute"] = {},
  ["@boolean"] = {},
  ["@character"] = {},
  ["@character.special"] = {},
  ["@comment"] = { link = "Comment"},
  ["@comment.documentation"] = {},
  ["@comment.error"] = {},
  ["@comment.note"] = {},
  ["@comment.todo"] = {},
  ["@comment.warning"] = {},
  ["@conditional"] = {},
  ["@constant"] = {},
  ["@constant.builtin"] = {},
  ["@constant.macro"] = {},
  ["@constructor"] = {},
  ["@debug"] = {},
  ["@define"] = {},
  ["@exception"] = {},
  ["@field"] = {},
  ["@float"] = {},
  ["@function"] = {},
  ["@function.builtin"] = {},
  ["@function.call"] = {},
  ["@function.macro"] = {},
  ["@include"] = {},
  ["@keyword"] = {},
  ["@keyword.function"] = {},
  ["@keyword.operator"] = {},
  ["@keyword.return"] = {},
  ["@label"] = {},
  ["@markup.link"] = {},
  ["@method"] = {},
  ["@method.call"] = {},
  ["@namespace"] = {},
  ["@none"] = {},
  ["@number"] = {},
  ["@operator"] = {},
  ["@parameter"] = {},
  ["@parameter.reference"] = {},
  ["@preproc"] = {},
  ["@property"] = {},
  ["@punctuation.bracket"] = {},
  ["@punctuation.delimiter"] = {},
  ["@punctuation.special"] = {},
  ["@repeat"] = {},
  ["@storageclass"] = {},
  ["@string"] = { fg = c.yellow },
  ["@string.documentation"] = {},
  ["@string.escape"] = {},
  ["@string.regexp"] = {},
  ["@string.special"] = {},
  ["@symbol"] = {},
  ["@tag"] = {},
  ["@tag.attribute"] = {},
  ["@tag.delimiter"] = {},
  ["@text"] = {},
  ["@text.danger"] = {},
  ["@text.emphasis"] = {},
  ["@text.environment"] = {},
  ["@text.environment.name"] = {},
  ["@text.literal"] = {},
  ["@text.math"] = {},
  ["@text.note"] = {},
  ["@text.reference"] = {},
  ["@text.strike"] = {},
  ["@text.strong"] = {},
  ["@text.title"] = {},
  ["@text.todo"] = {},
  ["@text.underline"] = {},
  ["@text.uri"] = {},
  ["@text.warning"] = {},
  ["@type"] = {},
  ["@type.builtin"] = {},
  ["@type.definition"] = {},
  ["@type.qualifier"] = {},
  ["@variable"] = {},
  ["@variable.builtin"] = {},
  ["@variable.parameter"] = {},

  -- LSP Semantic Token highlights (consistent with Treesitter)
  ["@lsp.type.boolean"] = {},
  ["@lsp.type.builtinType"] = {},
  ["@lsp.type.comment"] = {},
  ["@lsp.type.decorator"] = {},
  ["@lsp.type.deriveHelper"] = {},
  ["@lsp.type.enum"] = {},
  ["@lsp.type.enumMember"] = {},
  ["@lsp.type.escapeSequence"] = {},
  ["@lsp.type.formatSpecifier"] = {},
  ["@lsp.type.generic"] = {},
  ["@lsp.type.interface"] = {},
  ["@lsp.type.keyword"] = {},
  ["@lsp.type.lifetime"] = {},
  ["@lsp.type.namespace"] = {},
  ["@lsp.type.number"] = {},
  ["@lsp.type.operator"] = {},
  ["@lsp.type.parameter"] = {},
  ["@lsp.type.property"] = {},
  ["@lsp.type.selfKeyword"] = {},
  ["@lsp.type.selfTypeKeyword"] = {},
  ["@lsp.type.string"] = {},
  ["@lsp.type.typeAlias"] = {},
  ["@lsp.type.unresolvedReference"] = {},
  ["@lsp.type.variable"] = {},
  ["@lsp.typemod.class.defaultLibrary"] = {},
  ["@lsp.typemod.enum.defaultLibrary"] = {},
  ["@lsp.typemod.enumMember.defaultLibrary"] = {},
  ["@lsp.typemod.function.defaultLibrary"] = {},
  ["@lsp.typemod.keyword.async"] = {},
  ["@lsp.typemod.keyword.injected"] = { link = "@keyword" },
  ["@lsp.typemod.macro.defaultLibrary"] = { link = "@function.macro" },
  ["@lsp.typemod.method.defaultLibrary"] = { link = "@method" },
  ["@lsp.typemod.operator.injected"] = { link = "@operator" },
  ["@lsp.typemod.string.injected"] = { link = "@string" },
  ["@lsp.typemod.struct.defaultLibrary"] = { link = "@type.builtin" },
  ["@lsp.typemod.type.defaultLibrary"] = { link = "@type.builtin" },
  ["@lsp.typemod.typeAlias.defaultLibrary"] = { link = "@type.definition" },
  ["@lsp.typemod.variable.callable"] = { link = "@function" },
  ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
  ["@lsp.typemod.variable.injected"] = { link = "@variable" },
  ["@lsp.typemod.variable.static"] = { link = "@constant" },

  BlinkCmpMenu = {},
  BlinkCmpMenuBorder = {},
  BlinkCmpMenuSelection = {},
  BlinkCmpLabel = {},
  BlinkCmpLabelMatch = {},
  BlinkCmpLabelDescription = {},
  BlinkCmpLabelDetail = {},
  BlinkCmpKind = {},
  BlinkCmpKindText = {},
  BlinkCmpKindMethod = {},
  BlinkCmpKindFunction = {},
  BlinkCmpKindConstructor = {},
  BlinkCmpKindField = {},
  BlinkCmpKindVariable = {},
  BlinkCmpKindClass = {},
  BlinkCmpKindInterface = {},
  BlinkCmpKindModule = {},
  BlinkCmpKindProperty = {},
  BlinkCmpKindUnit = {},
  BlinkCmpKindValue = {},
  BlinkCmpKindEnum = {},
  BlinkCmpKindKeyword = {},
  BlinkCmpKindSnippet = {},
  BlinkCmpKindColor = {},
  BlinkCmpKindFile = {},
  BlinkCmpKindReference = {},
  BlinkCmpKindFolder = {},
  BlinkCmpKindEnumMember = {},
  BlinkCmpKindConstant = {},
  BlinkCmpKindStruct = {},
  BlinkCmpKindEvent = {},
  BlinkCmpKindOperator = {},
  BlinkCmpKindTypeParameter = {},

  NeoTreeBufferNumber = {},
  NeoTreeCursorLine = {},
  NeoTreeDimText = {},
  NeoTreeDirectoryIcon = {},
  NeoTreeDirectoryName = {},
  NeoTreeDotfile = {},
  NeoTreeFileIcon = {},
  NeoTreeFileName = {},
  NeoTreeFileNameOpened = {},
  NeoTreeFilterTerm = {},
  NeoTreeFloatBorder = {},
  NeoTreeFloatTitle = {},
  NeoTreeTitleBar = {},
  NeoTreeGitAdded = {},
  NeoTreeGitConflict = {},
  NeoTreeGitDeleted = {},
  NeoTreeGitIgnored = {},
  NeoTreeGitModified = {},
  NeoTreeGitUnstaged = {},
  NeoTreeGitUntracked = {},
  NeoTreeGitStaged = {},
  NeoTreeHiddenByName = {},
  NeoTreeIndentMarker = {},
  NeoTreeExpander = {},
  NeoTreeNormal = {},
  NeoTreeNormalNC = {},
  NeoTreeSignColumn = {},
  NeoTreeStats = {},
  NeoTreeStatsHeader = {},
  NeoTreeStatusLine = {},
  NeoTreeStatusLineNC = {},
  NeoTreeVertSplit = {},
  NeoTreeWinSeparator = {},
  NeoTreeEndOfBuffer = {},
  NeoTreeRootName = {},
  NeoTreeSymbolicLinkTarget = {},
  NeoTreeWindowsHidden = {},
}

-- Apply all highlights in a single loop for better performance
for grp, opts in pairs(highlights) do
  hl(0, grp, opts)
end

-- Update 'variable.builtin' to use a highlight of a higher priority
local key = "variable.builtin"
vim.api.nvim_create_autocmd("LspTokenUpdate", {
  callback = function (args)
    local t = args.data.token
    local captures = vim.treesitter.get_captures_at_pos(args.buf, t.line, t.start_col)

    for _, x in ipairs(captures) do
      if x.capture == key then
        hl_token(t, args.buf, args.data.client_id, "@" .. key, { priority = 126 })
        break
      end
    end
  end,
})
