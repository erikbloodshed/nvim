local g = vim.g
local o = vim.o
local cmd = vim.cmd
local api = vim.api

-- Clear existing highlights and reset syntax
cmd.highlight("clear")
if vim.fn.exists("syntax_on") then
  cmd.syntax("reset")
end

o.termguicolors = true
g.colors_name = "everforest-dark"

-- Color palette (unchanged from everforest-dark.lua)
local c = {
  none = "none",
  bg_dim = "#1E2326",
  bg0 = "#272E33",
  bg1 = "#2E383C",
  bg2 = "#374145",
  bg3 = "#414B50",
  bg4 = "#495156",
  bg5 = "#4F5B58",
  bg_visual = "#4C3743",
  bg_red = "#493B40",
  bg_yellow = "#45443C",
  bg_green = "#3C4841",
  bg_blue = "#384B55",
  bg_purple = "#463F48",
  fg = "#D3C6AA",
  red = "#E67E80",
  orange = "#E69987",
  yellow = "#DBBC7F",
  green = "#A7C080",
  aqua = "#83C092",
  blue = "#7FBBB3",
  purple = "#B08AC0",
  pink = "#D68BA6",
  grey0 = "#7A8478",
  grey1 = "#859289",
  grey2 = "#9DA9A0",
  statusline1 = "#A7C080",
  statusline2 = "#D3C6AA",
  statusline3 = "#E67E80"
}

-- Highlight groups based on Dracula specs
local highlights = {
  -- Editor highlights
  ColorColumn = { bg = c.bg1 },
  Cursor = { fg = c.bg0, bg = c.fg },
  CursorLine = { bg = c.bg3 },
  CursorLineNr = { fg = c.yellow, bold = true },
  EndOfBuffer = { fg = c.bg0 },
  ErrorMsg = { fg = c.red, bold = true },
  FloatBorder = { fg = c.grey1, bg = c.bg1 },
  FoldColumn = { fg = c.grey1, bg = c.bg0 },
  Folded = { fg = c.grey1, bg = c.bg1 },
  IncSearch = { fg = c.fg, bg = c.bg_purple },
  LineNr = { fg = c.grey1 },
  MatchParen = { fg = c.purple, bg = c.bg3 },
  ModeMsg = { fg = c.fg, bold = true },
  MoreMsg = { fg = c.green, bold = true },
  NonText = { fg = c.grey0 },
  Normal = { fg = c.fg, bg = c.none },
  NormalFloat = { fg = c.fg, bg = c.none },
  Pmenu = { fg = c.fg, bg = c.bg1 },
  PmenuSbar = { bg = c.bg2 },
  PmenuSel = { fg = c.fg, bg = c.bg_blue },
  PmenuThumb = { bg = c.grey2 },
  Question = { fg = c.green },
  Search = { fg = c.fg, bg = c.bg_blue },
  SignColumn = { bg = c.bg0 },
  SpecialKey = { fg = c.grey0 },
  StatusLine = { fg = c.statusline2, bg = c.bg2 },
  StatusLineNC = { fg = c.grey1, bg = c.bg1 },
  TabLine = { fg = c.grey1, bg = c.bg1 },
  TabLineFill = { bg = c.bg0 },
  TabLineSel = { fg = c.fg, bg = c.bg2, bold = true },
  VertSplit = { fg = c.bg3, bg = c.bg0 },
  Visual = { bg = c.bg_visual },
  WarningMsg = { fg = c.yellow, bold = true },
  WildMenu = { fg = c.fg, bg = c.bg_blue },
  WinSeparator = { fg = c.bg3, bg = c.bg0 },

  -- Syntax highlights
  Boolean = { fg = c.purple },
  Character = { fg = c.green },
  Comment = { fg = c.grey1, italic = true },
  SpecialComment = { fg = c.grey1, italic = true },
  Constant = { fg = c.purple },
  Delimiter = { fg = c.fg },
  Error = { fg = c.red },
  Float = { fg = c.purple },
  Function = { fg = c.green },
  Identifier = { fg = c.fg },
  Ignore = { fg = c.grey1 },
  Keyword = { fg = c.red },
  Number = { fg = c.purple },
  Operator = { fg = c.orange },
  PreProc = { fg = c.aqua },
  Special = { fg = c.blue },
  SpecialChar = { fg = c.yellow },
  Statement = { fg = c.purple },
  StorageClass = { fg = c.orage },
  String = { fg = c.yellow },
  Todo = { fg = c.bg0, bg = c.blue, bold = true },
  Type = { fg = c.yellow },
  Typedef = { fg = c.red },
  Underlined = { fg = c.blue, underline = true },

  -- Diagnostic highlights
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.yellow },
  DiagnosticInfo = { fg = c.blue },
  DiagnosticHint = { fg = c.aqua },
  DiagnosticUnderlineError = { sp = c.red, underline = true },
  DiagnosticUnderlineWarn = { sp = c.yellow, underline = true },
  DiagnosticUnderlineInfo = { sp = c.blue, underline = true },
  DiagnosticUnderlineHint = { sp = c.aqua, underline = true },

  -- Diff highlights
  DiffAdd = { fg = c.green, bg = c.bg_green },
  DiffChange = { fg = c.yellow, bg = c.bg_yellow },
  DiffDelete = { fg = c.red, bg = c.bg_red },
  DiffText = { fg = c.blue, bg = c.bg_blue },

  -- GitSigns highlights
  GitSignsAdd = { fg = c.green },
  GitSignsChange = { fg = c.yellow },
  GitSignsDelete = { fg = c.red },

  -- Treesitter highlights
  ["@comment"] = { link = "Comment" },
  ["@constant"] = { link = "Constant" },
  ["@string"] = { fg = c.yellow },
  ["@character"] = { link = "Character" },
  ["@function"] = { link = "Function" },
  ["@function.builtin"] = { link = "Function" },
  ["@function.call"] = { link = "Function" },
  ["@function.macro"] = { link = "Function" },
  ["@keyword"] = { link = "Keyword" },
  ["@keyword.function"] = { link = "Keyword" },
  ["@keyword.operator"] = { link = "Operator" },
  ["@keyword.return"] = { link = "Keyword" },
  ["@operator"] = { link = "Operator" },
  ["@type"] = { link = "Type" },
  ["@type.builtin"] = { link = "Type" },
  ["@variable"] = { link = "Identifier" },
  ["@variable.builtin"] = { fg = c.red, bold = true },
  ["@constant.builtin"] = { fg = c.purple, bold = true },
  ["@punctuation.bracket"] = { link = "Delimiter" },
  ["@punctuation.delimiter"] = { link = "Delimiter" },
  ["@punctuation.special"] = { link = "Delimiter" },
  ["@tag"] = { link = "Keyword" },
  ["@tag.attribute"] = { link = "Identifier" },
  ["@tag.delimiter"] = { link = "Delimiter" },
  ["@text.uri"] = { link = "Underlined" },
  ["@text.todo"] = { link = "Todo" },

  -- LSP Semantic Token highlights
  ["@lsp.type.comment"] = { link = "Comment" },
  ["@lsp.type.keyword"] = { link = "Keyword" },
  ["@lsp.type.string"] = { fg = c.yellow },
  ["@lsp.type.variable"] = { link = "Identifier" },
  ["@lsp.type.function"] = { link = "Function" },
  ["@lsp.type.method"] = { link = "Function" },
  ["@lsp.type.parameter"] = { link = "Identifier" },
  ["@lsp.type.type"] = { link = "Type" },
  ["@lsp.type.builtinType"] = { link = "Type" },
  ["@lsp.type.namespace"] = { link = "Identifier" },
  ["@lsp.type.enum"] = { link = "Type" },
  ["@lsp.type.enumMember"] = { link = "Constant" },
  ["@lsp.type.interface"] = { link = "Type" },
  ["@lsp.type.property"] = { link = "Identifier" },
  ["@lsp.typemod.function.defaultLibrary"] = { link = "Function" },
  ["@lsp.typemod.variable.defaultLibrary"] = { link = "Identifier" },
}

-- Set highlights
local hl = vim.api.nvim_set_hl
for group, opts in pairs(highlights) do
  hl(0, group, opts)
end

-- LSP semantic token priority handling
local key_priorities = {
  ["constant.builtin"] = 127,
  ["variable.builtin"] = 127
}

api.nvim_create_autocmd("LspTokenUpdate", {
  callback = function(args)
    local t = args.data.token
    local cap = vim.treesitter.get_captures_at_pos(args.buf, t.line, t.start_col)

    for _, x in ipairs(cap) do
      local priority = key_priorities[x.capture]
      if priority then
        vim.lsp.semantic_tokens.highlight_token(t, args.buf, args.data.client_id, "@" .. x.capture,
          { priority = priority })
        return
      end
    end
  end,
})
