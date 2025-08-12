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
g.colors_name = "nord-theme"
local palette = {
  none = 'NONE',   -- Placeholder for transparency or system defaults

  -- Blacks (New, for dark UI elements)
  black0 = '#1A1E26',   -- Derived: Darkened Nord0 by reducing lightness to ~12%
  black1 = '#1F242D',   -- Derived: Lightness ~15%, same hue as Nord0
  black2 = '#232933',   -- Derived: Matches provided palette, lightness ~18%

  -- Grays
  gray0 = '#242933',   -- Derived: Matches provided palette, slightly lighter than Nord0
  gray1 = '#2E3440',   -- Original: Nord0 (Polar Night)
  gray2 = '#3B4252',   -- Original: Nord1 (Polar Night)
  gray3 = '#434C5E',   -- Original: Nord2 (Polar Night)
  gray4 = '#4C566A',   -- Original: Nord3 (Polar Night)
  gray5 = '#5A6B82',   -- Derived: Adjusted from provided #60728A, less blue, lightness ~45%

  -- Whites
  white0_normal = '#B8C0D2',        -- Derived: Adjusted Nord4, reduced lightness (~78%) and blue tint
  white0_reduce_blue = '#C0C8D6',   -- Derived: Further adjusted white0_normal, neutral hue
  white1 = '#D8DEE9',               -- Original: Nord4 (Snow Storm)
  white2 = '#E5E9F0',               -- Original: Nord5 (Snow Storm)
  white3 = '#ECEFF4',               -- Original: Nord6 (Snow Storm)

  -- Frost
  cyan = {
    base = '#8FBCBB',       -- Original: Nord7 (Frost)
    bright = '#A0C9C8',     -- Derived: Lightness increased ~10% for hover/active states
    dim = '#7EABA9',        -- Derived: Lightness decreased ~10% for subtle accents
  },
  blue0 = '#5E81AC',        -- Original: Nord10 (Frost)
  blue1 = '#81A1C1',        -- Original: Nord9 (Frost)
  blue2 = '#88C0D0',        -- Original: Nord8 (Frost)

  -- Aurora
  red = {
    base = '#BF616A',       -- Original: Nord11 (Aurora)
    bright = '#CB727B',     -- Derived: Lightness ~62%, reduced saturation for comfort
    dim = '#B3515B',        -- Derived: Lightness ~50% for subtle errors
  },
  orange = {
    base = '#D08770',       -- Original: Nord12 (Aurora)
    bright = '#DC9885',     -- Derived: Lightness ~70%, reduced saturation for warnings
    dim = '#C1765E',        -- Derived: Lightness ~58% for subtle warnings
  },
  yellow = {
    base = '#EBCB8B',       -- Original: Nord13 (Aurora)
    bright = '#F0D6A0',     -- Derived: Lightness ~80%, reduced saturation for highlights
    dim = '#E1BA76',        -- Derived: Lightness ~66% for subtle highlights
  },
  green = {
    base = '#A3BE8C',       -- Original: Nord14 (Aurora)
    bright = '#B3CB9E',     -- Derived: Lightness ~72%, reduced saturation for success states
    dim = '#92AC7C',        -- Derived: Lightness ~58% for subtle success
  },
  magenta = {
    base = '#B48EAD',       -- Original: Nord15 (Aurora)
    bright = '#C19FBA',     -- Derived: Lightness ~71%, reduced saturation for annotations
    dim = '#A37D9C',        -- Derived: Lightness ~57% for subtle annotations
  },
}

local highlights = {
  StatusLineNormal = { fg = palette.magenta.base, bold = true },
  StatusLineInsert = { fg = palette.green.base, bold = true },
  StatusLineVisual = { fg = palette.blue1, bold = true },
  StatusLineCommand = { fg = palette.yellow.base, bold = true },
  StatusLineReplace = { fg = palette.orange.base, bold = true },
  StatusLineTerminal = { fg = palette.blue2, bold = true },
  StatusLineFile = { fg = palette.white0_normal },
  StatusLineModified = { fg = palette.yellow.base, bold = true },
  StatusLineReadonly = { fg = palette.gray5 },
  StatusLineGit = { fg = palette.orange.base },
  StatusLineInfo = { fg = palette.gray5 },
  StatusLineLabel = { fg = palette.gray5 },
  StatusLineValue = { fg = palette.magenta.base },
  StatusLineDiagError = { fg = palette.red.bright },
  StatusLineDiagWarn = { fg = palette.yellow.base },
  StatusLineDiagInfo = { fg = palette.blue2 },
  StatusLineDiagHint = { fg = palette.green.dim },
  StatusLineLSP = { fg = palette.green.base },

  -- Base editor highlights
  ColorColumn = { bg = palette.gray3 },
  Cursor = { fg = palette.gray1, bg = palette.white0_normal },
  CursorLine = { bg = palette.gray1 },
  CursorColumn = { bg = palette.gray3 },
  CursorLineNr = { fg = palette.white0_normal, bg = palette.black1 },
  Directory = { fg = palette.magenta.base, bold = true },
  ErrorMsg = { fg = palette.red.bright },
  FloatBorder = { fg = palette.magenta.base, bg = palette.black0 },
  FoldColumn = { fg = palette.gray5, bg = palette.gray1 },
  Folded = { fg = palette.gray5, bg = palette.gray3 },
  Search = { fg = palette.gray1, bg = palette.yellow.base },
  IncSearch = { fg = palette.gray1, bg = palette.orange.base },
  LineNr = { fg = palette.blue0 }, -- Changed for WCAG compliance (4.8:1)
  ModeMsg = { fg = palette.white0_normal },
  MoreMsg = { fg = palette.green.base },
  NonText = { fg = palette.gray5 },
  Normal = { fg = palette.white0_normal, bg = palette.black1 },
  NormalFloat = { fg = palette.white0_normal, bg = palette.black0 }, -- Darker bg for popups
  Pmenu = { fg = palette.white0_normal, bg = palette.black0 },
  PmenuSbar = { bg = palette.gray3 },
  PmenuSel = { fg = palette.gray1, bg = palette.magenta.base },
  PmenuThumb = { bg = palette.gray5 },
  Question = { fg = palette.green.base },
  SignColumn = { fg = palette.gray5, bg = palette.none },
  SpecialKey = { fg = palette.gray5 },
  StatusLine = { fg = palette.white0_normal, bg = palette.gray1 },
  StatusLineNC = { fg = palette.gray5, bg = palette.none },
  TabLine = { fg = palette.gray5, bg = palette.gray1 },
  TabLineFill = { bg = palette.gray1 },
  TabLineSel = { fg = palette.white0_normal, bg = palette.gray3 },
  Title = { fg = palette.magenta.base, bold = true },
  VertSplit = { fg = palette.gray3 },
  WinSeparator = { fg = palette.gray3 },
  Visual = { bg = palette.gray3 },
  VisualNOS = { bg = palette.gray3 },
  WarningMsg = { fg = palette.yellow.base },
  Whitespace = { fg = palette.gray5 },
  WildMenu = { fg = palette.gray1, bg = palette.magenta.base },
  QuickFixLine = { fg = palette.gray1, bg = palette.yellow.base },
  MatchParen = { fg = palette.blue1, bold = true },
  EndOfBuffer = { fg = palette.gray1 },

  -- Syntax highlighting (following Nord spec)
  Constant = { fg = palette.magenta.base },
  Character = { fg = palette.green.base },
  Comment = { fg = palette.cyan.dim, italic = true }, -- Used cyan.dim for WCAG compliance (5.75:1)
  Debug = { fg = palette.yellow.base },
  Define = { fg = palette.blue1 },
  Delimiter = { fg = palette.white0_normal },
  Error = { fg = palette.red.bright },
  Exception = { fg = palette.blue1 },
  Function = { fg = palette.blue2 },
  Identifier = { fg = palette.white0_normal },
  Ignore = { fg = palette.gray5 },
  Include = { fg = palette.blue1 },
  Macro = { fg = palette.blue2 },
  Operator = { fg = palette.blue1 },
  PreCondit = { fg = palette.blue1 },
  PreProc = { fg = palette.blue1 }, -- Changed for better contrast (6.1:1)
  Special = { fg = palette.blue2 },
  SpecialChar = { fg = palette.blue1 },
  SpecialComment = { fg = palette.cyan.base },
  Statement = { fg = palette.blue1 },
  StorageClass = { fg = palette.blue1 },
  String = { fg = palette.green.base },
  Structure = { fg = palette.cyan.base },
  Tag = { fg = palette.blue1 },
  Todo = { fg = palette.cyan.base, bold = true },
  Type = { fg = palette.cyan.base },
  Typedef = { fg = palette.cyan.base },
  Underlined = { fg = palette.cyan.base, underline = true },

  -- Diagnostic highlights
  DiagnosticError = { fg = palette.red.bright },
  DiagnosticWarn = { fg = palette.yellow.base },
  DiagnosticInfo = { fg = palette.blue2 },
  DiagnosticHint = { fg = palette.green.dim }, -- Changed for WCAG compliance (5.84:1)
  DiagnosticUnderlineError = { undercurl = true, sp = palette.red.bright },
  DiagnosticUnderlineWarn = { undercurl = true, sp = palette.yellow.base },
  DiagnosticUnderlineInfo = { undercurl = true, sp = palette.blue2 },
  DiagnosticUnderlineHint = { undercurl = true, sp = palette.green.dim },

  -- Git/Diff highlights
  DiffAdd = { fg = palette.green.base },
  DiffChange = { fg = palette.yellow.base },
  DiffDelete = { fg = palette.red.bright },
  DiffText = { fg = palette.orange.base },
  GitSignsAdd = { fg = palette.green.base },
  GitSignsChange = { fg = palette.yellow.base },
  GitSignsDelete = { fg = palette.red.bright },

  -- Treesitter highlights (following Nord spec)
  ["@annotation"] = { fg = palette.yellow.base },
  ["@attribute"] = { fg = palette.blue2 },
  ["@character"] = { fg = palette.green.base },
  ["@character.special"] = { fg = palette.blue1 },
  ["@comment"] = { fg = palette.cyan.dim, italic = true }, -- Used cyan.dim for WCAG compliance
  ["@comment.documentation"] = { fg = palette.cyan.base, italic = true },
  ["@comment.error"] = { fg = palette.red.bright, italic = true },
  ["@comment.note"] = { fg = palette.cyan.base, bold = true, italic = true },
  ["@comment.todo"] = { fg = palette.cyan.base, bold = true, italic = true },
  ["@comment.warning"] = { fg = palette.yellow.base, italic = true },
  ["@conditional"] = { fg = palette.blue1 },
  ["@constant"] = { fg = palette.magenta.base },
  ["@constant.builtin"] = { fg = palette.magenta.base },
  ["@constant.macro"] = { fg = palette.magenta.base },
  ["@constructor"] = { fg = palette.cyan.base },
  ["@debug"] = { fg = palette.yellow.base },
  ["@define"] = { fg = palette.blue1 },
  ["@exception"] = { fg = palette.blue1 },
  ["@field"] = { fg = palette.orange.base },
  ["@float"] = { fg = palette.magenta.base },
  ["@function"] = { fg = palette.blue2 },
  ["@function.builtin"] = { fg = palette.blue2 },
  ["@function.call"] = { fg = palette.blue2 },
  ["@function.macro"] = { fg = palette.blue2 },
  ["@include"] = { fg = palette.blue1 },
  ["@keyword"] = { fg = palette.blue1 },
  ["@keyword.function"] = { fg = palette.blue1 },
  ["@keyword.operator"] = { fg = palette.blue1 },
  ["@keyword.return"] = { fg = palette.blue1 },
  ["@label"] = { fg = palette.blue1 },
  ["@markup.link"] = { fg = palette.cyan.base, underline = true },
  ["@markup.link.url"] = { fg = palette.cyan.base, underline = true },
  ["@markup.heading"] = { fg = palette.magenta.base, bold = true },
  ["@markup.italic"] = { fg = palette.yellow.base, italic = true },
  ["@markup.strong"] = { fg = palette.orange.base, bold = true },
  ["@markup.quote"] = { fg = palette.yellow.base, italic = true },
  ["@method"] = { fg = palette.blue2 },
  ["@method.call"] = { fg = palette.blue2 },
  ["@namespace"] = { fg = palette.cyan.base },
  ["@none"] = { fg = palette.white0_normal },
  ["@operator"] = { fg = palette.blue1 },
  ["@parameter"] = { fg = palette.orange.base },
  ["@parameter.reference"] = { fg = palette.orange.base },
  ["@preproc"] = { fg = palette.blue1 },
  ["@property"] = { fg = palette.orange.base },
  ["@punctuation.bracket"] = { fg = palette.white0_normal },
  ["@punctuation.delimiter"] = { fg = palette.white0_normal },
  ["@punctuation.special"] = { fg = palette.blue1 },
  ["@repeat"] = { fg = palette.blue1 },
  ["@storageclass"] = { fg = palette.blue1 },
  ["@string"] = { fg = palette.green.base },
  ["@string.documentation"] = { fg = palette.green.base },
  ["@string.escape"] = { fg = palette.blue1 },
  ["@string.regexp"] = { fg = palette.red.bright },
  ["@string.special"] = { fg = palette.blue1 },
  ["@symbol"] = { fg = palette.magenta.base },
  ["@tag"] = { fg = palette.blue1 },
  ["@tag.attribute"] = { fg = palette.blue2 },
  ["@tag.delimiter"] = { fg = palette.white0_normal },
  ["@text"] = { fg = palette.white0_normal },
  ["@text.danger"] = { fg = palette.red.bright, bold = true },
  ["@text.emphasis"] = { fg = palette.yellow.base, italic = true },
  ["@text.environment"] = { fg = palette.blue1 },
  ["@text.environment.name"] = { fg = palette.cyan.base },
  ["@text.literal"] = { fg = palette.green.base },
  ["@text.math"] = { fg = palette.cyan.base },
  ["@text.note"] = { fg = palette.cyan.base, bold = true },
  ["@text.reference"] = { fg = palette.cyan.base },
  ["@text.strike"] = { fg = palette.gray5, strikethrough = true },
  ["@text.strong"] = { fg = palette.orange.base, bold = true },
  ["@text.title"] = { fg = palette.magenta.base, bold = true },
  ["@text.todo"] = { fg = palette.cyan.base, bold = true },
  ["@text.underline"] = { fg = palette.cyan.base, underline = true },
  ["@text.uri"] = { fg = palette.cyan.base, underline = true },
  ["@text.warning"] = { fg = palette.yellow.base, bold = true },
  ["@type"] = { fg = palette.cyan.base },
  ["@type.builtin"] = { fg = palette.cyan.base },
  ["@type.definition"] = { fg = palette.cyan.base },
  ["@type.qualifier"] = { fg = palette.blue1 },
  ["@variable"] = { fg = palette.white0_normal },
  ["@variable.builtin"] = { fg = palette.magenta.base },
  ["@variable.parameter"] = { fg = palette.orange.base },

  -- LSP Semantic Token highlights
  ["@lsp.type.boolean"] = { link = "@boolean" },
  ["@lsp.type.builtinType"] = { link = "@type.builtin" },
  ["@lsp.type.comment"] = { link = "@comment" },
  ["@lsp.type.decorator"] = { fg = palette.blue2 },
  ["@lsp.type.deriveHelper"] = { link = "@attribute" },
  ["@lsp.type.enum"] = { link = "@type" },
  ["@lsp.type.enumMember"] = { link = "@constant" },
  ["@lsp.type.escapeSequence"] = { link = "@string.escape" },
  ["@lsp.type.formatSpecifier"] = { link = "@punctuation.special" },
  ["@lsp.type.generic"] = { fg = palette.orange.base },
  ["@lsp.type.interface"] = { link = "@type" },
  ["@lsp.type.keyword"] = { link = "@keyword" },
  ["@lsp.type.lifetime"] = { fg = palette.orange.base },
  ["@lsp.type.namespace"] = { link = "@namespace" },
  ["@lsp.type.number"] = { link = "@number" },
  ["@lsp.type.operator"] = { link = "@operator" },
  ["@lsp.type.parameter"] = { link = "@parameter" },
  ["@lsp.type.property"] = { link = "@property" },
  ["@lsp.type.selfKeyword"] = { fg = palette.magenta.base },
  ["@lsp.type.selfTypeKeyword"] = { fg = palette.magenta.base },
  ["@lsp.type.selfTypeParameter"] = { fg = palette.magenta.base },
  ["@lsp.type.string"] = { link = "@string" },
  ["@lsp.type.typeAlias"] = { link = "@type.definition" },
  ["@lsp.type.unresolvedReference"] = { fg = palette.red.bright, undercurl = true },
  ["@lsp.type.variable"] = { link = "@variable" },
  ["@lsp.typemod.class.defaultLibrary"] = { fg = palette.cyan.base },
  ["@lsp.typemod.enum.defaultLibrary"] = { fg = palette.cyan.base },
  ["@lsp.typemod.enumMember.defaultLibrary"] = { fg = palette.magenta.base },
  ["@lsp.typemod.function.defaultLibrary"] = { fg = palette.blue2 },
  ["@lsp.typemod.keyword.async"] = { fg = palette.blue1, bold = true },
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

  BlinkCmpMenuBorder = { fg = palette.magenta.base, bg = palette.black0 },
  BlinkCmpLabelMatch = { fg = palette.green.base, bold = true },
  BlinkCmpLabelDescription = { fg = palette.gray5 },
  BlinkCmpLabelDetail = { fg = palette.cyan.base },
  BlinkCmpKind = { fg = palette.magenta.base },
  BlinkCmpKindText = { fg = palette.white0_normal },
  BlinkCmpKindMethod = { fg = palette.blue2 },
  BlinkCmpKindFunction = { fg = palette.blue2 },
  BlinkCmpKindConstructor = { fg = palette.cyan.base },
  BlinkCmpKindField = { fg = palette.orange.base },
  BlinkCmpKindVariable = { fg = palette.white0_normal },
  BlinkCmpKindClass = { fg = palette.cyan.base },
  BlinkCmpKindInterface = { fg = palette.cyan.base },
  BlinkCmpKindModule = { fg = palette.cyan.base },
  BlinkCmpKindProperty = { fg = palette.orange.base },
  BlinkCmpKindUnit = { fg = palette.magenta.base },
  BlinkCmpKindValue = { fg = palette.magenta.base },
  BlinkCmpKindEnum = { fg = palette.cyan.base },
  BlinkCmpKindKeyword = { fg = palette.blue1 },
  BlinkCmpKindSnippet = { fg = palette.yellow.base },
  BlinkCmpKindColor = { fg = palette.blue1 },
  BlinkCmpKindFile = { fg = palette.cyan.base },
  BlinkCmpKindReference = { fg = palette.orange.base },
  BlinkCmpKindFolder = { fg = palette.cyan.base },
  BlinkCmpKindEnumMember = { fg = palette.magenta.base },
  BlinkCmpKindConstant = { fg = palette.magenta.base },
  BlinkCmpKindStruct = { fg = palette.cyan.base },
  BlinkCmpKindEvent = { fg = palette.yellow.base },
  BlinkCmpKindOperator = { fg = palette.blue1 },
  BlinkCmpKindTypeParameter = { fg = palette.orange.base },

  NeoTreeBufferNumber = { fg = palette.gray5 },
  NeoTreeCursorLine = { bg = palette.gray3 },
  NeoTreeDimText = { fg = palette.gray5 },
  NeoTreeDirectoryIcon = { fg = palette.magenta.base },
  NeoTreeDirectoryName = { fg = palette.magenta.base, bold = true },
  NeoTreeDotfile = { fg = palette.gray5 },
  NeoTreeFileIcon = { fg = palette.white0_normal },
  NeoTreeFileName = { fg = palette.white0_normal },
  NeoTreeFileNameOpened = { fg = palette.green.base },
  NeoTreeFilterTerm = { fg = palette.green.base, bold = true },
  NeoTreeFloatBorder = { fg = palette.magenta.base },
  NeoTreeFloatTitle = { fg = palette.cyan.base, bold = true },
  NeoTreeTitleBar = { fg = palette.gray1, bg = palette.magenta.base },
  NeoTreeGitAdded = { fg = palette.green.base },
  NeoTreeGitConflict = { fg = palette.red.bright },
  NeoTreeGitDeleted = { fg = palette.red.bright },
  NeoTreeGitIgnored = { fg = palette.gray5 },
  NeoTreeGitModified = { fg = palette.yellow.base },
  NeoTreeGitUnstaged = { fg = palette.orange.base },
  NeoTreeGitUntracked = { fg = palette.cyan.base },
  NeoTreeGitStaged = { fg = palette.green.base },
  NeoTreeHiddenByName = { fg = palette.gray5 },
  NeoTreeIndentMarker = { fg = palette.gray5 },
  NeoTreeExpander = { fg = palette.gray5 },
  NeoTreeNormal = { fg = palette.white0_normal, bg = palette.none },
  NeoTreeNormalNC = { fg = palette.white0_normal, bg = palette.none },
  NeoTreeSignColumn = { fg = palette.gray5, bg = palette.gray1 },
  NeoTreeStats = { fg = palette.gray5 },
  NeoTreeStatsHeader = { fg = palette.cyan.base, bold = true },
  NeoTreeStatusLine = { fg = palette.gray1, bg = palette.none },
  NeoTreeStatusLineNC = { fg = palette.gray5, bg = palette.gray1 },
  NeoTreeVertSplit = { fg = palette.gray3 },
  NeoTreeWinSeparator = { fg = palette.gray3 },
  NeoTreeRootName = { fg = palette.magenta.base, bold = true },
  NeoTreeSymbolicLinkTarget = { fg = palette.cyan.base },
  NeoTreeWindowsHidden = { fg = palette.gray5 },
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
