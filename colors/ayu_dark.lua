-- Localize the API for performance
local hl = vim.api.nvim_set_hl
local hl_token = vim.lsp.semantic_tokens.highlight_token
local g = vim.g

-- Clear existing highlights to prevent conflicts
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

-- Set terminal colors and colorscheme name
vim.o.termguicolors = true
vim.g.colors_name = "ayu_dark"

-- Ayu Dark Color Palette structured like OneDark
local c = {
  -- Core Background Colors (Ayu Dark hierarchy)
  transparent = "none",
  bg0 = "#0F1419",  -- Main background (Ayu Dark signature)
  bg1 = "#0C0F16",  -- Slightly darker background (sidebars, popups)
  bg2 = "#161F26",  -- Lighter background (visual selection, current line)
  bg3 = "#4D5566",  -- Lightest background (borders, inactive elements)
  bg_d = "#0B0E14", -- Darker background variant

  -- Core Foreground Colors (Ayu Dark)
  fg = "#BFBDB6",         -- Main foreground text
  light_grey = "#E6E1CF", -- Primary text (brighter)
  grey = "#5C6773",       -- Secondary text (comments, less important)
  dark_grey = "#343F4C",  -- Tertiary text (line numbers, borders)

  -- Ayu Dark Signature Colors
  red = "#F07178",         -- Errors, delete operations
  green = "#B8CC52",       -- Strings, additions, success
  yellow = "#E6B673",      -- Classes, warnings, constants
  blue = "#59C2FF",        -- Functions, methods, links
  purple = "#D2A6FF",      -- Keywords, types, special
  cyan = "#95E6CB",        -- Operators, escape characters, info
  orange = "#F29668",      -- Numbers, constants, attributes
  pink = "#D96C75",        -- Pink accent

  dark_red = "#FF3333",    -- Darker red variant
  dark_green = "#98B982",  -- Darker green variant
  dark_yellow = "#D19A66", -- Darker yellow/orange variant
  dark_blue = "#6994BF",   -- Darker blue variant (alt_blue)
  dark_purple = "#A679D9", -- Darker purple variant
  dark_cyan = "#4CBB17",   -- Darker cyan variant

  -- UI and Special Colors (Ayu Dark)
  cursor_grey = "#161F26",  -- Cursor line background (selection)
  visual_grey = "#161F26",  -- Visual selection background
  menu_grey = "#151A1E",    -- Menu/popup backgrounds (dark_gray)
  special_grey = "#1F2430", -- Special backgrounds (gray)
  gutter_grey = "#4D5566",  -- Gutter, line numbers (ui_gray)
  comment_grey = "#5C6773", -- Comments, inactive text

  -- Git Colors (Ayu Dark Style)
  diff_add = "#B8CC52",    -- Git additions (using green)
  diff_delete = "#FF3333", -- Git deletions (using red)
  diff_change = "#E6B673", -- Git modifications (using yellow)
  diff_text = "#F29668",   -- Git diff text highlighting (using orange)
}

-- Main highlight groups following OneDark structure with Ayu Dark colors
local highlights = {
  -- Base highlights
  ColorColumn = { bg = c.bg2 },
  Cursor = { fg = c.bg0, bg = c.fg },
  CursorLine = { bg = c.cursor_grey },
  CursorColumn = { link = "CursorLine" },
  CursorLineNr = { fg = c.orange },
  Directory = { fg = c.blue },
  ErrorMsg = { fg = c.dark_red },
  FloatBorder = { fg = c.gutter_grey },
  FoldColumn = { fg = c.dark_grey, bg = c.bg0 },
  Folded = { fg = c.dark_grey, bg = c.menu_grey },
  Search = { fg = c.bg0, bg = c.yellow },
  IncSearch = { link = "Search" },
  LineNr = { fg = c.gutter_grey },
  ModeMsg = { fg = c.fg },
  MoreMsg = { fg = c.green },
  NonText = { fg = c.gutter_grey },
  Normal = { fg = c.fg, bg = c.transparent },
  NormalFloat = { fg = c.fg, bg = c.transparent },
  Pmenu = { fg = c.fg, bg = c.menu_grey },
  PmenuSbar = { bg = c.special_grey },
  PmenuSel = { fg = c.bg0, bg = c.dark_blue, bold = true },
  PmenuThumb = { bg = c.orange },
  Question = { fg = c.purple },
  SignColumn = { bg = c.bg0 },
  SpecialKey = { fg = c.gutter_grey },
  StatusLine = { fg = c.fg, bg = c.special_grey },
  StatusLineNC = { fg = c.dark_grey, bg = c.menu_grey },
  TabLine = { fg = c.dark_grey, bg = c.menu_grey },
  TabLineFill = { link = "TabLine" },
  TabLineSel = { fg = c.fg, bg = c.bg0 },
  Title = { fg = c.bg0, bg = c.blue, bold = true },
  VertSplit = { fg = c.gutter_grey },
  WinSeparator = { link = "VertSplit" },
  Visual = { bg = c.visual_grey },
  VisualNOS = { link = "Visual" },
  WarningMsg = { fg = c.yellow },
  Whitespace = { fg = c.gutter_grey },
  EndOfBuffer = { fg = c.bg0 },
  WildMenu = { fg = c.bg0, bg = c.orange },
  QuickFixLine = { bg = c.visual_grey },
  MatchParen = { fg = c.orange, bold = true },

  -- Syntax highlighting
  Boolean = { fg = c.orange },
  Character = { fg = c.yellow },
  Comment = { fg = c.comment_grey, italic = true },
  Conditional = { fg = c.orange },
  Constant = { fg = c.orange },
  Debug = { fg = c.red },
  Define = { fg = c.orange },
  Delimiter = { fg = c.fg },
  Error = { fg = c.red },
  Exception = { fg = c.orange },
  Float = { fg = c.purple },
  Function = { fg = c.blue },
  Identifier = { fg = c.fg },
  Ignore = { fg = c.gutter_grey },
  Include = { fg = c.orange },
  Keyword = { fg = c.purple },
  Label = { fg = c.orange },
  Macro = { fg = c.orange },
  Number = { fg = c.orange },
  Operator = { fg = c.orange },
  PreCondit = { fg = c.orange },
  PreProc = { fg = c.yellow },
  Repeat = { fg = c.purple },
  Special = { fg = c.orange },
  SpecialChar = { fg = c.orange },
  SpecialComment = { fg = c.dark_grey },
  Statement = { fg = c.orange },
  StorageClass = { fg = c.orange },
  String = { fg = c.green },
  Structure = { fg = c.yellow },
  Tag = { fg = c.orange },
  Todo = { fg = c.yellow, bold = true },
  Type = { fg = c.yellow },
  Typedef = { fg = c.yellow },
  Underlined = { fg = c.cyan, underline = true },

  -- Diagnostic highlights (Ayu Dark style)
  DiagnosticError = { fg = c.dark_red },
  DiagnosticWarn = { fg = c.dark_yellow },
  DiagnosticInfo = { fg = c.dark_blue },
  DiagnosticHint = { fg = c.dark_grey },
  DiagnosticVirtualTextError = { fg = c.red, bg = c.menu_grey },
  DiagnosticVirtualTextWarn = { fg = c.yellow, bg = c.menu_grey },
  DiagnosticVirtualTextInfo = { fg = c.blue, bg = c.menu_grey },
  DiagnosticVirtualTextHint = { fg = c.dark_grey, bg = c.menu_grey },
  DiagnosticUnderlineError = { undercurl = true, sp = c.dark_red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.dark_yellow },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.dark_blue },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.dark_grey },

  -- Git highlights (Ayu Dark style)
  DiffAdd = { fg = c.green, bg = c.menu_grey },
  DiffChange = { fg = c.yellow, bg = c.menu_grey },
  DiffDelete = { fg = c.red, bg = c.menu_grey },
  DiffText = { fg = c.yellow, bg = c.bg2 },
  GitSignsAdd = { fg = c.green },
  GitSignsChange = { fg = c.yellow },
  GitSignsDelete = { fg = c.red },

  -- Treesitter highlights (Ayu Dark mappings)
  ["@annotation"] = { fg = c.yellow },
  ["@attribute"] = { fg = c.yellow },
  ["@boolean"] = { fg = c.orange },
  ["@character"] = { fg = c.orange },
  ["@character.special"] = { fg = c.orange },
  ["@comment"] = { fg = c.comment_grey, italic = true },
  ["@comment.documentation"] = { fg = c.dark_grey },
  ["@comment.error"] = { fg = c.bg0, bg = c.dark_red, bold = true },
  ["@comment.note"] = { fg = c.bg0, bg = c.dark_cyan, bold = true },
  ["@comment.todo"] = { fg = c.bg0, bg = c.dark_yellow, bold = true },
  ["@comment.warning"] = { fg = c.yellow },
  ["@conditional"] = { link = "Keyword" },
  ["@constant"] = { fg = c.orange },
  ["@constant.builtin"] = { fg = c.orange },
  ["@constant.macro"] = { fg = c.orange },
  ["@constructor"] = { fg = c.yellow },
  ["@debug"] = { fg = c.red },
  ["@define"] = { fg = c.orange },
  ["@exception"] = { fg = c.orange },
  ["@field"] = { fg = c.fg },
  ["@float"] = { link = "Number" },
  ["@function"] = { fg = c.blue },
  ["@function.builtin"] = { fg = c.blue },
  ["@function.call"] = { fg = c.blue },
  ["@function.macro"] = { fg = c.blue },
  ["@include"] = { fg = c.orange },
  ["@keyword"] = { link = "Keyword" },
  ["@keyword.function"] = { link = "Keyword" },
  ["@keyword.operator"] = { link = "Keyword" },
  ["@keyword.return"] = { link = "Keyword" },
  ["@label"] = { fg = c.orange },
  ["@markup.link"] = { fg = c.blue },
  ["@method"] = { fg = c.blue },
  ["@method.call"] = { fg = c.blue },
  ["@namespace"] = { fg = c.yellow },
  ["@none"] = { fg = c.fg },
  ["@number"] = { link = "Number" },
  ["@operator"] = { link = "Keyword" },
  ["@parameter"] = { fg = c.red },
  ["@parameter.reference"] = { fg = c.fg },
  ["@preproc"] = { fg = c.orange },
  ["@property"] = { fg = c.blue },
  ["@punctuation.bracket"] = { fg = c.fg },
  ["@punctuation.delimiter"] = { fg = c.fg },
  ["@punctuation.special"] = { fg = c.orange },
  ["@repeat"] = { fg = c.orange },
  ["@storageclass"] = { fg = c.orange },
  ["@string"] = { fg = c.green },
  ["@string.documentation"] = { fg = c.green },
  ["@string.escape"] = { fg = c.orange },
  ["@string.regexp"] = { fg = c.red },
  ["@string.special"] = { fg = c.orange },
  ["@symbol"] = { fg = c.yellow },
  ["@tag"] = { fg = c.orange },
  ["@tag.attribute"] = { fg = c.blue },
  ["@tag.delimiter"] = { fg = c.fg },
  ["@text"] = { fg = c.fg },
  ["@text.danger"] = { fg = c.red },
  ["@text.emphasis"] = { italic = true },
  ["@text.environment"] = { fg = c.orange },
  ["@text.environment.name"] = { fg = c.yellow },
  ["@text.literal"] = { fg = c.green },
  ["@text.math"] = { fg = c.yellow },
  ["@text.note"] = { fg = c.cyan },
  ["@text.reference"] = { fg = c.cyan },
  ["@text.strike"] = { strikethrough = true },
  ["@text.strong"] = { bold = true },
  ["@text.title"] = { fg = c.orange, bold = true },
  ["@text.todo"] = { fg = c.yellow, bold = true },
  ["@text.underline"] = { underline = true },
  ["@text.uri"] = { fg = c.cyan, undercurl = true },
  ["@text.warning"] = { fg = c.yellow },
  ["@type"] = { fg = c.yellow },
  ["@type.builtin"] = { fg = c.yellow },
  ["@type.definition"] = { fg = c.yellow },
  ["@type.qualifier"] = { fg = c.orange },
  ["@variable"] = { fg = c.fg },
  ["@variable.builtin"] = { fg = c.orange },
  ["@variable.parameter"] = { link = "@parameter" },

  -- LSP Semantic Token highlights (consistent with Treesitter)
  ["@lsp.type.boolean"] = { link = "@boolean" },
  ["@lsp.type.builtinType"] = { link = "@type.builtin" },
  ["@lsp.type.comment"] = { link = "@comment" },
  ["@lsp.type.decorator"] = { link = "@annotation" },
  ["@lsp.type.deriveHelper"] = { link = "@annotation" },
  ["@lsp.type.enum"] = { link = "@type" },
  ["@lsp.type.enumMember"] = { link = "@constant" },
  ["@lsp.type.escapeSequence"] = { link = "@string.escape" },
  ["@lsp.type.formatSpecifier"] = { link = "@punctuation.special" },
  ["@lsp.type.generic"] = { link = "@type" },
  ["@lsp.type.interface"] = { link = "@type" },
  ["@lsp.type.keyword"] = { link = "@keyword" },
  ["@lsp.type.lifetime"] = { link = "@annotation" },
  ["@lsp.type.namespace"] = { link = "@namespace" },
  ["@lsp.type.number"] = { link = "@number" },
  ["@lsp.type.operator"] = { link = "@operator" },
  ["@lsp.type.parameter"] = { link = "@parameter" },
  ["@lsp.type.property"] = { link = "@property" },
  ["@lsp.type.selfKeyword"] = { link = "@variable.builtin" },
  ["@lsp.type.selfTypeKeyword"] = { link = "@variable.builtin" },
  ["@lsp.type.string"] = { link = "@string" },
  ["@lsp.type.typeAlias"] = { link = "@type.definition" },
  ["@lsp.type.unresolvedReference"] = { fg = c.red, undercurl = true },
  ["@lsp.type.variable"] = { link = "@variable" },
  ["@lsp.typemod.class.defaultLibrary"] = { link = "@type.builtin" },
  ["@lsp.typemod.enum.defaultLibrary"] = { link = "@type.builtin" },
  ["@lsp.typemod.enumMember.defaultLibrary"] = { link = "@constant.builtin" },
  ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
  ["@lsp.typemod.keyword.async"] = { link = "@keyword" },
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
}

-- Modular highlights for plugins (Ayu Dark colors)
local plug = {
  blink_cmp = {
    BlinkCmpMenu = { link = "Pmenu" },
    BlinkCmpMenuBorder = { fg = c.gutter_grey, bg = c.menu_grey },
    BlinkCmpMenuSelection = { link = "PmenuSel" },
    BlinkCmpLabel = { fg = c.fg },
    BlinkCmpLabelMatch = { fg = c.yellow, bold = true },
    BlinkCmpLabelDescription = { fg = c.dark_grey },
    BlinkCmpLabelDetail = { fg = c.dark_grey },
    BlinkCmpKind = { fg = c.orange },
    BlinkCmpKindText = { fg = c.fg },
    BlinkCmpKindMethod = { fg = c.blue },
    BlinkCmpKindFunction = { fg = c.blue },
    BlinkCmpKindConstructor = { fg = c.orange },
    BlinkCmpKindField = { fg = c.fg },
    BlinkCmpKindVariable = { fg = c.orange },
    BlinkCmpKindClass = { fg = c.yellow },
    BlinkCmpKindInterface = { fg = c.yellow },
    BlinkCmpKindModule = { fg = c.yellow },
    BlinkCmpKindProperty = { fg = c.fg },
    BlinkCmpKindUnit = { fg = c.orange },
    BlinkCmpKindValue = { fg = c.orange },
    BlinkCmpKindEnum = { fg = c.yellow },
    BlinkCmpKindKeyword = { fg = c.orange },
    BlinkCmpKindSnippet = { fg = c.green },
    BlinkCmpKindColor = { fg = c.red },
    BlinkCmpKindFile = { fg = c.green },
    BlinkCmpKindReference = { fg = c.fg },
    BlinkCmpKindFolder = { fg = c.yellow },
    BlinkCmpKindEnumMember = { fg = c.orange },
    BlinkCmpKindConstant = { fg = c.orange },
    BlinkCmpKindStruct = { fg = c.yellow },
    BlinkCmpKindEvent = { fg = c.orange },
    BlinkCmpKindOperator = { fg = c.orange },
    BlinkCmpKindTypeParameter = { fg = c.yellow },
  },
  neotree = {
    NeoTreeBufferNumber = { fg = c.orange },
    NeoTreeCursorLine = { bg = c.special_grey },
    NeoTreeDimText = { fg = c.dark_grey },
    NeoTreeDirectoryIcon = { link = "Directory" },
    NeoTreeDirectoryName = { link = "Directory", bold = true },
    NeoTreeDotfile = { fg = c.dark_grey },
    NeoTreeFileIcon = { fg = c.fg },
    NeoTreeFileName = { fg = c.fg },
    NeoTreeFileNameOpened = { fg = c.blue, italic = true },
    NeoTreeFilterTerm = { fg = c.blue },
    NeoTreeFloatBorder = { fg = c.orange },
    NeoTreeFloatTitle = { fg = c.orange, bold = true },
    NeoTreeTitleBar = { fg = c.orange, bg = c.bg0, bold = true },
    NeoTreeGitAdded = { fg = c.green },
    NeoTreeGitConflict = { fg = c.red, bold = true },
    NeoTreeGitDeleted = { fg = c.red },
    NeoTreeGitIgnored = { fg = c.dark_grey, italic = true },
    NeoTreeGitModified = { fg = c.yellow },
    NeoTreeGitUnstaged = { fg = c.yellow },
    NeoTreeGitUntracked = { fg = c.orange },
    NeoTreeGitStaged = { fg = c.green },
    NeoTreeHiddenByName = { fg = c.dark_grey },
    NeoTreeIndentMarker = { fg = c.dark_grey },
    NeoTreeExpander = { fg = c.fg },
    NeoTreeNormal = { fg = c.fg, bg = c.transparent },
    NeoTreeNormalNC = { fg = c.dark_grey, bg = c.transparent },
    NeoTreeSignColumn = { bg = c.bg0 },
    NeoTreeStats = { fg = c.green },
    NeoTreeStatsHeader = { fg = c.orange, bold = true },
    NeoTreeStatusLine = { fg = c.fg, bg = c.special_grey },
    NeoTreeStatusLineNC = { fg = c.dark_grey, bg = c.special_grey },
    NeoTreeVertSplit = { fg = c.gutter_grey, bg = c.bg0 },
    NeoTreeWinSeparator = { fg = c.gutter_grey, bg = c.bg0 },
    NeoTreeEndOfBuffer = { fg = c.bg0 },
    NeoTreeRootName = { fg = c.orange, bold = true },
    NeoTreeSymbolicLinkTarget = { fg = c.cyan, italic = true },
    NeoTreeWindowsHidden = { fg = c.dark_grey },
  },
}

highlights = vim.tbl_extend("force", highlights, plug.blink_cmp, plug.neotree)

-- Apply all highlights in a single loop for better performance
for group, opts in pairs(highlights) do
  hl(0, group, opts)
end

-- Terminal colors (Ayu Dark 16-color palette)
g.terminal_color_0 = c.bg0         -- black
g.terminal_color_1 = c.red         -- red
g.terminal_color_2 = c.green       -- green
g.terminal_color_3 = c.yellow      -- yellow
g.terminal_color_4 = c.blue        -- blue
g.terminal_color_5 = c.purple      -- magenta
g.terminal_color_6 = c.cyan        -- cyan
g.terminal_color_7 = c.fg          -- white
g.terminal_color_8 = c.grey        -- bright black
g.terminal_color_9 = c.red         -- bright red
g.terminal_color_10 = c.green      -- bright green
g.terminal_color_11 = c.yellow     -- bright yellow
g.terminal_color_12 = c.blue       -- bright blue
g.terminal_color_13 = c.purple     -- bright magenta
g.terminal_color_14 = c.cyan       -- bright cyan
g.terminal_color_15 = c.light_grey -- bright white

-- Update 'variable.builtin' to use a highlight of a higher priority
local target = "variable.builtin"
vim.api.nvim_create_autocmd("LspTokenUpdate", {
  callback = function(args)
    local token = args.data.token
    local captures = vim.treesitter.get_captures_at_pos(args.buf, token.line, token.start_col)

    for _, x in ipairs(captures) do
      if x.capture == target then
        hl_token(token, args.buf, args.data.client_id, "@" .. target, { priority = 126 })
        break
      end
    end
  end,
})
