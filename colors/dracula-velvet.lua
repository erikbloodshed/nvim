local g = vim.g
local o = vim.o
local cmd = vim.cmd
local api = vim.api

cmd.highlight("clear")
if vim.fn.exists("syntax_on") then
  cmd.syntax("reset")
end

o.termguicolors = true
g.colors_name = "dracula-velvet"

local c = {
  none = "NONE",
  background = '#1a1a2e',
  foreground = "#e2dce8",
  selection = '#302c4a',
  comment = '#6272a4',
  red = "#ff5555",
  orange = "#ffb86c",
  yellow = "#f1fa8c",
  green = "#50fa7b",
  purple = "#bf9aff",
  cyan = "#8be9fd",
  pink = "#ff79c6",

  ansi_black = "#21222c",
  ansi_red = "#ff5555",
  ansi_green = "#50fa7b",
  ansi_yellow = "#f1fa8c",
  ansi_blue = "#bd93f9",
  ansi_magenta = "#ff79c6",
  ansi_cyan = "#8be9fd",
  ansi_white = "#f8f8f2",
  ansi_bright_black = "#6272a4",
  ansi_bright_red = "#ff6e6e",
  ansi_bright_green = "#69ff94",
  ansi_bright_yellow = "#ffffa5",
  ansi_bright_blue = "#d6acff",
  ansi_bright_magenta = "#ff92df",
  ansi_bright_cyan = "#a4ffff",
  ansi_bright_white = "#ffffff",
}

-- Set terminal colors
g.terminal_color_0 = c.ansi_black
g.terminal_color_1 = c.ansi_red
g.terminal_color_2 = c.ansi_green
g.terminal_color_3 = c.ansi_yellow
g.terminal_color_4 = c.ansi_blue
g.terminal_color_5 = c.ansi_magenta
g.terminal_color_6 = c.ansi_cyan
g.terminal_color_7 = c.ansi_white
g.terminal_color_8 = c.ansi_bright_black
g.terminal_color_9 = c.ansi_bright_red
g.terminal_color_10 = c.ansi_bright_green
g.terminal_color_11 = c.ansi_bright_yellow
g.terminal_color_12 = c.ansi_bright_blue
g.terminal_color_13 = c.ansi_bright_magenta
g.terminal_color_14 = c.ansi_bright_cyan
g.terminal_color_15 = c.ansi_bright_white

local highlights = {
  -- Base editor highlights
  ColorColumn = { bg = c.selection },
  Cursor = { fg = c.background, bg = c.foreground },
  CursorLine = { bg = c.selection },
  CursorColumn = { bg = c.selection },
  CursorLineNr = { fg = c.foreground, bg = c.selection },
  Directory = { fg = c.cyan },
  ErrorMsg = { fg = c.red },
  FloatBorder = { fg = c.purple },
  FoldColumn = { fg = c.comment, bg = c.background },
  Folded = { fg = c.comment, bg = c.selection },
  Search = { fg = c.background, bg = c.yellow },
  IncSearch = { fg = c.background, bg = c.orange },
  LineNr = { fg = c.comment },
  ModeMsg = { fg = c.foreground },
  MoreMsg = { fg = c.green },
  NonText = { fg = c.comment },
  Normal = { fg = c.foreground, bg = c.none },
  NormalFloat = { fg = c.foreground, bg = c.background },
  Pmenu = { fg = c.foreground, bg = c.selection },
  PmenuSbar = { bg = c.selection },
  PmenuSel = { fg = c.background, bg = c.purple },
  PmenuThumb = { bg = c.comment },
  Question = { fg = c.green },
  SignColumn = { fg = c.comment, bg = c.background },
  SpecialKey = { fg = c.comment },
  StatusLine = { fg = c.foreground, bg = c.selection },
  StatusLineNC = { fg = c.comment, bg = c.background },
  TabLine = { fg = c.comment, bg = c.background },
  TabLineFill = { bg = c.background },
  TabLineSel = { fg = c.foreground, bg = c.selection },
  Title = { fg = c.purple, bold = true },
  VertSplit = { fg = c.selection },
  WinSeparator = { fg = c.selection },
  Visual = { bg = c.selection },
  VisualNOS = { bg = c.selection },
  WarningMsg = { fg = c.yellow },
  Whitespace = { fg = c.comment },
  EndOfBuffer = { fg = c.background },
  WildMenu = { fg = c.background, bg = c.purple },
  QuickFixLine = { fg = c.background, bg = c.yellow },
  MatchParen = { fg = c.pink, underline = true },

  -- Syntax highlighting (following Dracula spec)
  Constant = { fg = c.purple },
  Character = { fg = c.green },
  Comment = { fg = c.comment, italic = true },
  Debug = { fg = c.yellow },
  Define = { fg = c.pink },
  Delimiter = { fg = c.foreground },
  Error = { fg = c.red },
  Exception = { fg = c.pink },
  Function = { fg = c.green },
  Identifier = { fg = c.foreground },
  Ignore = { fg = c.comment },
  Include = { fg = c.pink },
  Macro = { fg = c.green },
  Operator = { fg = c.pink },
  PreCondit = { fg = c.pink },
  PreProc = { fg = c.pink },
  Special = { fg = c.green },
  SpecialChar = { fg = c.pink },
  SpecialComment = { fg = c.cyan },
  Statement = { fg = c.pink },
  StorageClass = { fg = c.pink },
  String = { fg = c.yellow },
  Structure = { fg = c.cyan },
  Tag = { fg = c.pink },
  Todo = { fg = c.cyan, bold = true },
  Type = { fg = c.cyan },
  Typedef = { fg = c.cyan },
  Underlined = { fg = c.cyan, underline = true },

  -- Diagnostic highlights
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.yellow },
  DiagnosticInfo = { fg = c.cyan },
  DiagnosticHint = { fg = c.comment },
  DiagnosticUnderlineError = { undercurl = true, sp = c.red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.yellow },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.cyan },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.comment },

  -- Git/Diff highlights
  DiffAdd = { fg = c.green },
  DiffChange = { fg = c.yellow },
  DiffDelete = { fg = c.red },
  DiffText = { fg = c.orange },
  GitSignsAdd = { fg = c.green },
  GitSignsChange = { fg = c.yellow },
  GitSignsDelete = { fg = c.red },

  -- Treesitter highlights (following Dracula spec)
  ["@annotation"] = { fg = c.yellow },
  ["@attribute"] = { fg = c.green },
  ["@character"] = { fg = c.green },
  ["@character.special"] = { fg = c.pink },
  ["@comment"] = { fg = c.comment, italic = true },
  ["@comment.documentation"] = { fg = c.cyan, italic = true },
  ["@comment.error"] = { fg = c.red, italic = true },
  ["@comment.note"] = { fg = c.cyan, bold = true, italic = true },
  ["@comment.todo"] = { fg = c.cyan, bold = true, italic = true },
  ["@comment.warning"] = { fg = c.yellow, italic = true },
  ["@conditional"] = { fg = c.pink },
  ["@constant"] = { fg = c.purple },
  ["@constant.builtin"] = { fg = c.purple },
  ["@constant.macro"] = { fg = c.purple },
  ["@constructor"] = { fg = c.cyan },
  ["@debug"] = { fg = c.yellow },
  ["@define"] = { fg = c.pink },
  ["@exception"] = { fg = c.pink },
  ["@field"] = { fg = c.orange },
  ["@float"] = { fg = c.purple },
  ["@function"] = { fg = c.green },
  ["@function.builtin"] = { fg = c.green },
  ["@function.call"] = { fg = c.green },
  ["@function.macro"] = { fg = c.green },
  ["@include"] = { fg = c.pink },
  ["@keyword"] = { fg = c.pink },
  ["@keyword.function"] = { fg = c.pink },
  ["@keyword.operator"] = { fg = c.pink },
  ["@keyword.return"] = { fg = c.pink },
  ["@label"] = { fg = c.pink },
  ["@markup.link"] = { fg = c.cyan, underline = true },
  ["@markup.link.url"] = { fg = c.cyan, underline = true },
  ["@markup.heading"] = { fg = c.purple, bold = true },
  ["@markup.italic"] = { fg = c.yellow, italic = true },
  ["@markup.strong"] = { fg = c.orange, bold = true },
  ["@markup.quote"] = { fg = c.yellow, italic = true },
  ["@method"] = { fg = c.green },
  ["@method.call"] = { fg = c.green },
  ["@namespace"] = { fg = c.cyan },
  ["@none"] = { fg = c.foreground },
  ["@operator"] = { fg = c.pink },
  ["@parameter"] = { fg = c.orange },
  ["@parameter.reference"] = { fg = c.orange },
  ["@preproc"] = { fg = c.pink },
  ["@property"] = { fg = c.orange },
  ["@punctuation.bracket"] = { fg = c.foreground },
  ["@punctuation.delimiter"] = { fg = c.foreground },
  ["@punctuation.special"] = { fg = c.pink },
  ["@repeat"] = { fg = c.pink },
  ["@storageclass"] = { fg = c.pink },
  ["@string"] = { fg = c.yellow },
  ["@string.documentation"] = { fg = c.yellow },
  ["@string.escape"] = { fg = c.pink },
  ["@string.regexp"] = { fg = c.red },
  ["@string.special"] = { fg = c.pink },
  ["@symbol"] = { fg = c.purple },
  ["@tag"] = { fg = c.pink },
  ["@tag.attribute"] = { fg = c.green },
  ["@tag.delimiter"] = { fg = c.foreground },
  ["@text"] = { fg = c.foreground },
  ["@text.danger"] = { fg = c.red, bold = true },
  ["@text.emphasis"] = { fg = c.yellow, italic = true },
  ["@text.environment"] = { fg = c.pink },
  ["@text.environment.name"] = { fg = c.cyan },
  ["@text.literal"] = { fg = c.yellow },
  ["@text.math"] = { fg = c.cyan },
  ["@text.note"] = { fg = c.cyan, bold = true },
  ["@text.reference"] = { fg = c.cyan },
  ["@text.strike"] = { fg = c.comment, strikethrough = true },
  ["@text.strong"] = { fg = c.orange, bold = true },
  ["@text.title"] = { fg = c.purple, bold = true },
  ["@text.todo"] = { fg = c.cyan, bold = true },
  ["@text.underline"] = { fg = c.cyan, underline = true },
  ["@text.uri"] = { fg = c.cyan, underline = true },
  ["@text.warning"] = { fg = c.yellow, bold = true },
  ["@type"] = { fg = c.cyan },
  ["@type.builtin"] = { fg = c.cyan },
  ["@type.definition"] = { fg = c.cyan },
  ["@type.qualifier"] = { fg = c.pink },
  ["@variable"] = { fg = c.foreground },
  ["@variable.builtin"] = { fg = c.purple },
  ["@variable.parameter"] = { fg = c.orange },

  -- LSP Semantic Token highlights
  ["@lsp.type.boolean"] = { link = "@boolean" },
  ["@lsp.type.builtinType"] = { link = "@type.builtin" },
  ["@lsp.type.comment"] = { link = "@comment" },
  ["@lsp.type.decorator"] = { fg = c.green },
  ["@lsp.type.deriveHelper"] = { link = "@attribute" },
  ["@lsp.type.enum"] = { link = "@type" },
  ["@lsp.type.enumMember"] = { link = "@constant" },
  ["@lsp.type.escapeSequence"] = { link = "@string.escape" },
  ["@lsp.type.formatSpecifier"] = { link = "@punctuation.special" },
  ["@lsp.type.generic"] = { fg = c.orange },
  ["@lsp.type.interface"] = { link = "@type" },
  ["@lsp.type.keyword"] = { link = "@keyword" },
  ["@lsp.type.lifetime"] = { fg = c.orange },
  ["@lsp.type.namespace"] = { link = "@namespace" },
  ["@lsp.type.number"] = { link = "@number" },
  ["@lsp.type.operator"] = { link = "@operator" },
  ["@lsp.type.parameter"] = { link = "@parameter" },
  ["@lsp.type.property"] = { link = "@property" },
  ["@lsp.type.selfKeyword"] = { fg = c.purple },
  ["@lsp.type.selfTypeKeyword"] = { fg = c.purple },
  ["@lsp.type.selfTypeParameter"] = { fg = c.purple },
  ["@lsp.type.string"] = { link = "@string" },
  ["@lsp.type.typeAlias"] = { link = "@type.definition" },
  ["@lsp.type.unresolvedReference"] = { fg = c.red, undercurl = true },
  ["@lsp.type.variable"] = { link = "@variable" },
  ["@lsp.typemod.class.defaultLibrary"] = { fg = c.cyan },
  ["@lsp.typemod.enum.defaultLibrary"] = { fg = c.cyan },
  ["@lsp.typemod.enumMember.defaultLibrary"] = { fg = c.purple },
  ["@lsp.typemod.function.defaultLibrary"] = { fg = c.green },
  ["@lsp.typemod.keyword.async"] = { fg = c.pink, bold = true },
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

  BlinkCmpMenuBorder = { fg = c.purple },
  BlinkCmpLabelMatch = { fg = c.green, bold = true },
  BlinkCmpLabelDescription = { fg = c.comment },
  BlinkCmpLabelDetail = { fg = c.cyan },
  BlinkCmpKind = { fg = c.purple },
  BlinkCmpKindText = { fg = c.foreground },
  BlinkCmpKindMethod = { fg = c.green },
  BlinkCmpKindFunction = { fg = c.green },
  BlinkCmpKindConstructor = { fg = c.cyan },
  BlinkCmpKindField = { fg = c.orange },
  BlinkCmpKindVariable = { fg = c.foreground },
  BlinkCmpKindClass = { fg = c.cyan },
  BlinkCmpKindInterface = { fg = c.cyan },
  BlinkCmpKindModule = { fg = c.cyan },
  BlinkCmpKindProperty = { fg = c.orange },
  BlinkCmpKindUnit = { fg = c.purple },
  BlinkCmpKindValue = { fg = c.purple },
  BlinkCmpKindEnum = { fg = c.cyan },
  BlinkCmpKindKeyword = { fg = c.pink },
  BlinkCmpKindSnippet = { fg = c.yellow },
  BlinkCmpKindColor = { fg = c.pink },
  BlinkCmpKindFile = { fg = c.cyan },
  BlinkCmpKindReference = { fg = c.orange },
  BlinkCmpKindFolder = { fg = c.cyan },
  BlinkCmpKindEnumMember = { fg = c.purple },
  BlinkCmpKindConstant = { fg = c.purple },
  BlinkCmpKindStruct = { fg = c.cyan },
  BlinkCmpKindEvent = { fg = c.yellow },
  BlinkCmpKindOperator = { fg = c.pink },
  BlinkCmpKindTypeParameter = { fg = c.orange },
}

local hl = vim.api.nvim_set_hl
local hl_token = vim.lsp.semantic_tokens.highlight_token

for group, opts in pairs(highlights) do
  hl(0, group, opts)
end

local key_priorities = {
  ["constant.builtin"] = 127,
}

api.nvim_create_autocmd("LspTokenUpdate", {
  callback = function(args)
    local t = args.data.token
    local cap = vim.treesitter.get_captures_at_pos(args.buf, t.line, t.start_col)

    for _, x in ipairs(cap) do
      local priority = key_priorities[x.capture]
      if priority then
        hl_token(t, args.buf, args.data.client_id, "@" .. x.capture, { priority = priority })
        return
      end
    end
  end,
})

