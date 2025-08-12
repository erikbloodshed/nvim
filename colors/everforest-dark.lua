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
  purple = "#D699B6",
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
  Normal = { fg = c.fg, bg = c.bg0 },
  NormalFloat = { fg = c.fg, bg = c.bg1 },
  Cursor = { fg = c.bg0, bg = c.fg },
  CursorLine = { bg = c.bg1 },
  CursorLineNr = { fg = c.yellow, bold = true },
  LineNr = { fg = c.grey1 },
  SignColumn = { bg = c.bg0 },
  StatusLine = { fg = c.statusline2, bg = c.bg2 },
  StatusLineNC = { fg = c.grey1, bg = c.bg1 },
  VertSplit = { fg = c.bg3, bg = c.bg0 },
  WinSeparator = { fg = c.bg3, bg = c.bg0 },
  Visual = { bg = c.bg_visual },
  Search = { fg = c.fg, bg = c.bg_blue },
  IncSearch = { fg = c.fg, bg = c.bg_purple },
  Pmenu = { fg = c.fg, bg = c.bg1 },
  PmenuSel = { fg = c.fg, bg = c.bg_blue },
  PmenuSbar = { bg = c.bg2 },
  PmenuThumb = { bg = c.grey2 },
  FloatBorder = { fg = c.grey1, bg = c.bg1 },
  ColorColumn = { bg = c.bg1 },
  Folded = { fg = c.grey1, bg = c.bg1 },
  FoldColumn = { fg = c.grey1, bg = c.bg0 },
  TabLine = { fg = c.grey1, bg = c.bg1 },
  TabLineSel = { fg = c.fg, bg = c.bg2, bold = true },
  TabLineFill = { bg = c.bg0 },
  NonText = { fg = c.grey0 },
  SpecialKey = { fg = c.grey0 },
  ErrorMsg = { fg = c.red, bold = true },
  WarningMsg = { fg = c.yellow, bold = true },
  MoreMsg = { fg = c.green, bold = true },
  ModeMsg = { fg = c.fg, bold = true },
  Question = { fg = c.green },
  WildMenu = { fg = c.fg, bg = c.bg_blue },
  MatchParen = { fg = c.yellow, bg = c.bg3, bold = true },
  EndOfBuffer = { fg = c.grey0 },

  -- Syntax highlights
  Comment = { fg = c.grey1, italic = true },
  Constant = { fg = c.purple },
  String = { fg = c.yellow },
  Character = { fg = c.green },
  Identifier = { fg = c.red },
  Function = { fg = c.green },
  Statement = { fg = c.purple },
  Operator = { fg = c.purple },
  Keyword = { fg = c.purple },
  PreProc = { fg = c.aqua },
  Type = { fg = c.yellow },
  Special = { fg = c.blue },
  Delimiter = { fg = c.fg },
  Underlined = { fg = c.blue, underline = true },
  Error = { fg = c.red, underline = true },
  Todo = { fg = c.yellow, bg = c.bg0, bold = true },

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
        vim.lsp.semantic_tokens.highlight_token(t, args.buf, args.data.client_id, "@" .. x.capture, { priority = priority })
        return
      end
    end
  end,
})
