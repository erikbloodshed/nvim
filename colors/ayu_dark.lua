-- Localize the API for performance
local hl = vim.api.nvim_set_hl

-- Clear existing highlights to prevent conflicts
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end

-- Set terminal colors and colorscheme name
vim.o.termguicolors = true
vim.g.colors_name = "ayu_dark"

local colors = {
    bg          = "#0B0E14", -- Background
    bg2         = "#0C0F16", -- Background
    fg          = "#BFBDB6", -- Foreground
    selection   = "#161F26", -- Current-line/selection
    comment     = "#5C6773", -- Comment
    red         = "#F07178", -- Red
    orange      = "#F29668", -- Orange
    yellow      = "#E6B673", -- Yellow
    green       = "#B8CC52", -- Green
    purple      = "#D2A6FF", -- Purple
    cyan        = "#95E6CB", -- Cyan
    pink        = "#D96C75", -- Pink
    dark_gray   = "#151A1E", -- Secondary background
    gray        = "#1F2430", -- Tertiary background
    light_gray  = "#343F4C", -- Quaternary background
    fg2         = "#E6E1CF", -- Secondary foreground
    fg3         = "#D9D7CE", -- Tertiary foreground
    fg4         = "#C7C5BD", -- Quaternary foreground
    alt_blue    = "#6994BF", -- Alternative blue
    ui_gray     = "#4D5566", -- UI elements
    dark_cyan   = "#4CBB17", -- Darker cyan variant
    bright_blue = "#59C2FF"  -- Bright blue
}

-- Main highlight groups, including base and syntax
-- Links are defined directly in this table
local highlights = {
    -- Base highlights
    ColorColumn = { bg = colors.selection },
    Cursor = { fg = colors.bg, bg = colors.fg },
    CursorLine = { bg = colors.selection },
    CursorColumn = { link = "CursorLine" },
    CursorLineNr = { fg = colors.orange },
    Directory = { fg = colors.bright_blue },
    ErrorMsg = { fg = colors.red },
    FloatBorder = { fg = colors.ui_gray },
    FoldColumn = { fg = colors.light_gray, bg = colors.bg },
    Folded = { fg = colors.light_gray, bg = colors.dark_gray },
    Search = { fg = colors.bg, bg = colors.yellow },
    IncSearch = { link = "Search" },
    LineNr = { fg = colors.ui_gray },
    ModeMsg = { fg = colors.fg },
    MoreMsg = { fg = colors.green },
    NonText = { fg = colors.ui_gray },
    Normal = { fg = colors.fg, bg = colors.bg },
    NormalFloat = { fg = colors.fg, bg = colors.bg2 },
    Pmenu = { fg = colors.fg, bg = colors.dark_gray },
    PmenuSbar = { bg = colors.gray },
    PmenuSel = { fg = colors.bg, bg = colors.orange, bold = true },
    PmenuThumb = { bg = colors.orange },
    Question = { fg = colors.purple },
    SignColumn = { bg = colors.bg },
    SpecialKey = { fg = colors.ui_gray },
    StatusLine = { fg = colors.fg, bg = colors.gray },
    StatusLineNC = { fg = colors.light_gray, bg = colors.dark_gray },
    TabLine = { fg = colors.light_gray, bg = colors.dark_gray },
    TabLineFill = { link = "TabLine" },
    TabLineSel = { fg = colors.fg, bg = colors.bg },
    Title = { fg = colors.bg, bg = colors.cyan, bold = true, },
    VertSplit = { fg = colors.ui_gray },
    WinSeparator = { link = "VertSplit" },
    Visual = { bg = colors.selection },
    VisualNOS = { link = "Visual" },
    WarningMsg = { fg = colors.yellow },
    Whitespace = { fg = colors.ui_gray },
    EndOfBuffer = { fg = colors.bg },

    -- Syntax highlighting
    Boolean = { fg = colors.orange },
    Character = { fg = colors.yellow },
    Comment = { fg = colors.comment, italic = true },
    Conditional = { fg = colors.orange },
    Constant = { fg = colors.orange },
    Debug = { fg = colors.red },
    Define = { fg = colors.orange },
    Delimiter = { fg = colors.fg },
    Error = { fg = colors.red },
    Exception = { fg = colors.orange },
    Float = { fg = colors.purple },
    Function = { fg = colors.bright_blue },
    Identifier = { fg = colors.fg },
    Ignore = { fg = colors.ui_gray },
    Include = { fg = colors.orange },
    Keyword = { fg = colors.purple },
    Label = { fg = colors.orange },
    Macro = { fg = colors.orange },
    Number = { fg = colors.orange },
    Operator = { fg = colors.orange },
    PreCondit = { fg = colors.orange },
    PreProc = { fg = colors.yellow },
    Repeat = { fg = colors.purple },
    Special = { fg = colors.orange },
    SpecialChar = { fg = colors.orange },
    SpecialComment = { fg = colors.light_gray },
    Statement = { fg = colors.orange },
    StorageClass = { fg = colors.orange },
    String = { fg = colors.green },
    Structure = { fg = colors.yellow },
    Tag = { fg = colors.orange },
    Todo = { fg = colors.yellow, bold = true },
    Type = { fg = colors.yellow },
    Typedef = { fg = colors.yellow },
    Underlined = { fg = colors.cyan, underline = true },

    -- Treesitter highlights
    ["@annotation"] = { fg = colors.yellow },
    ["@attribute"] = { fg = colors.yellow },
    ["@boolean"] = { fg = colors.orange },
    ["@character"] = { fg = colors.orange },
    ["@character.special"] = { fg = colors.orange },
    ["@comment"] = { fg = colors.comment, italic = true },
    ["@comment.documentation"] = { fg = colors.light_gray },
    ["@comment.error"] = { fg = colors.red },
    ["@comment.note"] = { fg = colors.cyan },
    ["@comment.todo"] = { fg = colors.yellow, bold = true },
    ["@comment.warning"] = { fg = colors.yellow },
    ["@conditional"] = { link = "Keyword" },
    ["@constant"] = { fg = colors.orange },
    ["@constant.builtin"] = { fg = colors.orange },
    ["@constant.macro"] = { fg = colors.orange },
    ["@constructor"] = { fg = colors.yellow },
    ["@debug"] = { fg = colors.red },
    ["@define"] = { fg = colors.orange },
    ["@exception"] = { fg = colors.orange },
    ["@field"] = { fg = colors.fg },
    ["@float"] = { link = "Number" },
    ["@function"] = { fg = colors.bright_blue },
    ["@function.builtin"] = { fg = colors.bright_blue },
    ["@function.call"] = { fg = colors.bright_blue },
    ["@function.macro"] = { fg = colors.bright_blue },
    ["@include"] = { fg = colors.orange },
    ["@keyword"] = { link = "Keyword" },
    ["@keyword.function"] = { link = "Keyword" },
    ["@keyword.operator"] = { link = "Keyword" },
    ["@keyword.return"] = { link = "Keyword" },
    ["@label"] = { fg = colors.orange },
    ["@markup.link"] = { fg = colors.cyan },
    ["@method"] = { fg = colors.bright_blue },
    ["@method.call"] = { fg = colors.bright_blue },
    ["@namespace"] = { fg = colors.yellow },
    ["@none"] = { fg = colors.fg },
    ["@number"] = { link = "Number" },
    ["@operator"] = { link = "Keyword" },
    ["@parameter"] = { fg = colors.red },
    ["@parameter.reference"] = { fg = colors.fg },
    ["@preproc"] = { fg = colors.orange },
    ["@property"] = { fg = colors.fg },
    ["@punctuation.bracket"] = { fg = colors.fg },
    ["@punctuation.delimiter"] = { fg = colors.fg },
    ["@punctuation.special"] = { fg = colors.orange },
    ["@repeat"] = { fg = colors.orange },
    ["@storageclass"] = { fg = colors.orange },
    ["@string"] = { fg = colors.green },
    ["@string.documentation"] = { fg = colors.green },
    ["@string.escape"] = { fg = colors.orange },
    ["@string.regexp"] = { fg = colors.red },
    ["@string.special"] = { fg = colors.orange },
    ["@symbol"] = { fg = colors.yellow },
    ["@tag"] = { fg = colors.orange },
    ["@tag.attribute"] = { fg = colors.bright_blue },
    ["@tag.delimiter"] = { fg = colors.fg },
    ["@text"] = { fg = colors.fg },
    ["@text.danger"] = { fg = colors.red },
    ["@text.emphasis"] = { italic = true },
    ["@text.environment"] = { fg = colors.orange },
    ["@text.environment.name"] = { fg = colors.yellow },
    ["@text.literal"] = { fg = colors.green },
    ["@text.math"] = { fg = colors.yellow },
    ["@text.note"] = { fg = colors.cyan },
    ["@text.reference"] = { fg = colors.cyan },
    ["@text.strike"] = { strikethrough = true },
    ["@text.strong"] = { bold = true },
    ["@text.title"] = { fg = colors.orange, bold = true },
    ["@text.todo"] = { fg = colors.yellow, bold = true },
    ["@text.underline"] = { underline = true },
    ["@text.uri"] = { fg = colors.cyan, undercurl = true },
    ["@text.warning"] = { fg = colors.yellow },
    ["@type"] = { fg = colors.yellow },
    ["@type.builtin"] = { fg = colors.yellow },
    ["@type.definition"] = { fg = colors.yellow },
    ["@type.qualifier"] = { fg = colors.orange },
    ["@variable"] = { fg = colors.fg },
    ["@variable.builtin"] = { fg = colors.orange },
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
    ["@lsp.type.unresolvedReference"] = { fg = colors.red, undercurl = true },
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

    -- Diagnostic highlights
    DiagnosticError = { fg = colors.red },
    DiagnosticWarn = { fg = colors.yellow },
    DiagnosticInfo = { fg = colors.bright_blue },
    DiagnosticHint = { fg = colors.light_gray },
    DiagnosticVirtualTextError = { fg = colors.red, bg = colors.dark_gray },
    DiagnosticVirtualTextWarn = { fg = colors.yellow, bg = colors.dark_gray },
    DiagnosticVirtualTextInfo = { fg = colors.bright_blue, bg = colors.dark_gray },
    DiagnosticVirtualTextHint = { fg = colors.light_gray, bg = colors.dark_gray },
    DiagnosticUnderlineError = { undercurl = true, sp = colors.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = colors.yellow },
    DiagnosticUnderlineInfo = { undercurl = true, sp = colors.bright_blue },
    DiagnosticUnderlineHint = { undercurl = true, sp = colors.light_gray },

    -- Git highlights
    DiffAdd = { fg = colors.green, bg = colors.dark_gray },
    DiffChange = { fg = colors.yellow, bg = colors.dark_gray },
    DiffDelete = { fg = colors.red, bg = colors.dark_gray },
    DiffText = { fg = colors.yellow, bg = colors.selection },
    GitSignsAdd = { fg = colors.green },
    GitSignsChange = { fg = colors.yellow },
    GitSignsDelete = { fg = colors.red },
}

-- Modular highlights for plugins
local integrations = {
    blink_cmp = {
        BlinkCmpMenu = { link = "Pmenu" },
        BlinkCmpMenuBorder = { fg = colors.ui_gray, bg = colors.dark_gray },
        BlinkCmpMenuSelection = { link = "PmenuSel" },
        BlinkCmpLabel = { fg = colors.fg },
        BlinkCmpLabelMatch = { fg = colors.yellow, bold = true },
        BlinkCmpLabelDescription = { fg = colors.light_gray },
        BlinkCmpLabelDetail = { fg = colors.light_gray },
        BlinkCmpKind = { fg = colors.orange },
        BlinkCmpKindText = { fg = colors.fg },
        BlinkCmpKindMethod = { fg = colors.bright_blue },
        BlinkCmpKindFunction = { fg = colors.bright_blue },
        BlinkCmpKindConstructor = { fg = colors.orange },
        BlinkCmpKindField = { fg = colors.fg },
        BlinkCmpKindVariable = { fg = colors.orange },
        BlinkCmpKindClass = { fg = colors.yellow },
        BlinkCmpKindInterface = { fg = colors.yellow },
        BlinkCmpKindModule = { fg = colors.yellow },
        BlinkCmpKindProperty = { fg = colors.fg },
        BlinkCmpKindUnit = { fg = colors.orange },
        BlinkCmpKindValue = { fg = colors.orange },
        BlinkCmpKindEnum = { fg = colors.yellow },
        BlinkCmpKindKeyword = { fg = colors.orange },
        BlinkCmpKindSnippet = { fg = colors.green },
        BlinkCmpKindColor = { fg = colors.red },
        BlinkCmpKindFile = { fg = colors.green },
        BlinkCmpKindReference = { fg = colors.fg },
        BlinkCmpKindFolder = { fg = colors.yellow },
        BlinkCmpKindEnumMember = { fg = colors.orange },
        BlinkCmpKindConstant = { fg = colors.orange },
        BlinkCmpKindStruct = { fg = colors.yellow },
        BlinkCmpKindEvent = { fg = colors.orange },
        BlinkCmpKindOperator = { fg = colors.orange },
        BlinkCmpKindTypeParameter = { fg = colors.yellow },
    },
    neotree = {
        NeoTreeBufferNumber = { fg = colors.orange },
        NeoTreeCursorLine = { bg = colors.gray },
        NeoTreeDimText = { fg = colors.light_gray },
        NeoTreeDirectoryIcon = { link = "Directory" },
        NeoTreeDirectoryName = { link = "Directory", bold = true },
        NeoTreeDotfile = { fg = colors.light_gray },
        NeoTreeFileIcon = { fg = colors.fg },
        NeoTreeFileName = { fg = colors.fg },
        NeoTreeFileNameOpened = { fg = colors.bright_blue, italic = true },
        NeoTreeFilterTerm = { fg = colors.bright_blue },
        NeoTreeFloatBorder = { fg = colors.orange },
        NeoTreeFloatTitle = { fg = colors.orange, bold = true },
        NeoTreeTitleBar = { fg = colors.orange, bg = colors.bg, bold = true },
        NeoTreeGitAdded = { fg = colors.green },
        NeoTreeGitConflict = { fg = colors.red, bold = true },
        NeoTreeGitDeleted = { fg = colors.red },
        NeoTreeGitIgnored = { fg = colors.light_gray, italic = true },
        NeoTreeGitModified = { fg = colors.yellow },
        NeoTreeGitUnstaged = { fg = colors.yellow },
        NeoTreeGitUntracked = { fg = colors.orange },
        NeoTreeGitStaged = { fg = colors.green },
        NeoTreeHiddenByName = { fg = colors.light_gray },
        NeoTreeIndentMarker = { fg = colors.light_gray },
        NeoTreeExpander = { fg = colors.fg },
        NeoTreeNormal = { fg = colors.fg, bg = colors.bg },
        NeoTreeNormalNC = { fg = colors.light_gray, bg = colors.bg },
        NeoTreeSignColumn = { bg = colors.bg },
        NeoTreeStats = { fg = colors.green },
        NeoTreeStatsHeader = { fg = colors.orange, bold = true },
        NeoTreeStatusLine = { fg = colors.fg, bg = colors.gray },
        NeoTreeStatusLineNC = { fg = colors.light_gray, bg = colors.gray },
        NeoTreeVertSplit = { fg = colors.ui_gray, bg = colors.bg },
        NeoTreeWinSeparator = { fg = colors.ui_gray, bg = colors.bg },
        NeoTreeEndOfBuffer = { fg = colors.bg },
        NeoTreeRootName = { fg = colors.orange, bold = true },
        NeoTreeSymbolicLinkTarget = { fg = colors.cyan, italic = true },
        NeoTreeWindowsHidden = { fg = colors.light_gray },
    }
}

-- Apply all highlights in a single loop for better performance
for group, opts in pairs(highlights) do
    hl(0, group, opts)
end

for group, opts in pairs(integrations.blink_cmp) do
    hl(0, group, opts)
end

for group, opts in pairs(integrations.neotree) do
    hl(0, group, opts)
end
