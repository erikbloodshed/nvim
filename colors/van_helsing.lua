-- dracula.lua

-- Localize the API for performance
local hl = vim.api.nvim_set_hl

-- Clear existing highlights to prevent conflicts
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end

-- Set terminal colors and colorscheme name
vim.o.termguicolors = true
vim.g.colors_name = "van_helsing"

local colors = {
    bg = "#0B0D0F",         -- Background
    fg = "#F8F8F2",         -- Foreground
    selection = "#414D58",  -- Current-line/selection
    comment = "#708DA9",    -- Comment
    red = "#FF9580",        -- Red
    orange = "#FFCA80",     -- Orange
    yellow = "#FFFF80",     -- Yellow
    green = "#8AFF80",      -- Green
    purple = "#9580FF",     -- Purple
    cyan = "#80FFEA",       -- Cyan
    pink = "#FF80BF",       -- Pink
    dark_gray = "#1F272E",  -- Secondary background
    gray = "#29333D",       -- Tertiary background
    light_gray = "#33404C", -- Quaternary background
    fg2 = "#EDEDDE",        -- Secondary foreground
    fg3 = "#D6D6C2",        -- Tertiary foreground
    fg4 = "#BABAAB",        -- Quaternary foreground
    alt_blue = "#8A75F0"    -- Alternative blue
}

-- Main highlight groups, including base and syntax
-- Links are defined directly in this table
local highlights = {
    -- Base highlights
    ColorColumn = { bg = colors.selection },
    Cursor = { fg = colors.bg, bg = colors.fg },
    CursorLine = { bg = colors.selection },
    CursorColumn = { link = "CursorLine" },
    CursorLineNr = { fg = colors.fg },
    Directory = { fg = colors.cyan },
    ErrorMsg = { fg = colors.red },
    FloatBorder = { fg = colors.gray },
    FoldColumn = { fg = colors.light_gray, bg = colors.bg },
    Folded = { fg = colors.light_gray, bg = colors.dark_gray },
    Search = { fg = colors.bg, bg = colors.orange },
    IncSearch = { link = "Search" },
    LineNr = { fg = colors.light_gray },
    ModeMsg = { fg = colors.fg },
    MoreMsg = { fg = colors.green },
    NonText = { fg = colors.gray },
    Normal = { fg = colors.fg, bg = colors.bg },
    NormalFloat = { fg = colors.fg, bg = colors.bg },
    Pmenu = { fg = colors.fg, bg = colors.dark_gray },
    PmenuSbar = { bg = colors.gray },
    PmenuSel = { fg = colors.bg, bg = colors.purple, bold = true },
    PmenuThumb = { bg = colors.purple },
    Question = { fg = colors.purple },
    SignColumn = { bg = colors.bg },
    SpecialKey = { fg = colors.gray },
    StatusLine = { fg = colors.fg, bg = colors.gray },
    StatusLineNC = { fg = colors.light_gray, bg = colors.dark_gray },
    TabLine = { fg = colors.light_gray, bg = colors.dark_gray },
    TabLineFill = { link = "TabLine" },
    TabLineSel = { fg = colors.fg, bg = colors.bg },
    Title = { fg = colors.purple },
    VertSplit = { fg = colors.gray },
    WinSeparator = { link = "VertSplit" },
    Visual = { bg = colors.selection },
    VisualNOS = { link = "Visual" },
    WarningMsg = { fg = colors.orange },
    Whitespace = { fg = colors.gray },
    EndOfBuffer = { fg = colors.bg },

    -- Syntax highlighting
    Boolean = { fg = colors.purple },
    Character = { fg = colors.yellow },
    Comment = { fg = colors.comment, italic = true },
    Conditional = { fg = colors.pink },
    Constant = { fg = colors.purple },
    Debug = { fg = colors.red },
    Define = { fg = colors.pink },
    Delimiter = { fg = colors.fg },
    Error = { fg = colors.red },
    Exception = { fg = colors.pink },
    Float = { fg = colors.purple },
    Function = { fg = colors.green },
    Identifier = { fg = colors.fg },
    Ignore = { fg = colors.gray },
    Include = { fg = colors.pink },
    Keyword = { fg = colors.pink },
    Label = { fg = colors.pink },
    Macro = { fg = colors.pink },
    Number = { fg = colors.purple },
    Operator = { fg = colors.pink },
    PreCondit = { fg = colors.pink },
    PreProc = { fg = colors.pink },
    Repeat = { fg = colors.pink },
    Special = { fg = colors.pink },
    SpecialChar = { fg = colors.pink },
    SpecialComment = { fg = colors.light_gray },
    Statement = { fg = colors.pink },
    StorageClass = { fg = colors.pink },
    String = { fg = colors.yellow },
    Structure = { fg = colors.cyan },
    Tag = { fg = colors.pink },
    Todo = { fg = colors.orange, bold = true },
    Type = { fg = colors.cyan },
    Typedef = { fg = colors.cyan },
    Underlined = { fg = colors.cyan, underline = true },

    -- Treesitter highlights
    ["@annotation"] = { fg = colors.orange },
    ["@attribute"] = { fg = colors.cyan },
    ["@boolean"] = { fg = colors.purple },
    ["@character"] = { fg = colors.yellow },
    ["@character.special"] = { fg = colors.pink },
    ["@comment"] = { fg = colors.comment, italic = true },
    ["@comment.documentation"] = { fg = colors.light_gray },
    ["@comment.error"] = { fg = colors.red },
    ["@comment.note"] = { fg = colors.cyan },
    ["@comment.todo"] = { fg = colors.orange, bold = true },
    ["@comment.warning"] = { fg = colors.orange },
    ["@conditional"] = { fg = colors.pink },
    ["@constant"] = { fg = colors.purple },
    ["@constant.builtin"] = { fg = colors.purple },
    ["@constant.macro"] = { fg = colors.purple },
    ["@constructor"] = { fg = colors.cyan },
    ["@debug"] = { fg = colors.red },
    ["@define"] = { fg = colors.pink },
    ["@exception"] = { fg = colors.pink },
    ["@field"] = { fg = colors.orange },
    ["@float"] = { fg = colors.purple },
    ["@function"] = { fg = colors.green },
    ["@function.builtin"] = { fg = colors.green },
    ["@function.call"] = { fg = colors.green },
    ["@function.macro"] = { fg = colors.green },
    ["@include"] = { fg = colors.pink },
    ["@keyword"] = { fg = colors.pink },
    ["@keyword.function"] = { fg = colors.pink },
    ["@keyword.operator"] = { fg = colors.pink },
    ["@keyword.return"] = { fg = colors.pink },
    ["@label"] = { fg = colors.pink },
    ["@markup.link"] = { fg = colors.cyan },
    ["@method"] = { fg = colors.green },
    ["@method.call"] = { fg = colors.green },
    ["@namespace"] = { fg = colors.cyan },
    ["@none"] = { fg = colors.fg },
    ["@number"] = { fg = colors.purple },
    ["@operator"] = { fg = colors.pink },
    ["@parameter"] = { fg = colors.orange },
    ["@parameter.reference"] = { fg = colors.orange },
    ["@preproc"] = { fg = colors.pink },
    ["@property"] = { fg = colors.orange },
    ["@punctuation.bracket"] = { fg = colors.fg },
    ["@punctuation.delimiter"] = { fg = colors.fg },
    ["@punctuation.special"] = { fg = colors.pink },
    ["@repeat"] = { fg = colors.pink },
    ["@storageclass"] = { fg = colors.pink },
    ["@string"] = { fg = colors.yellow },
    ["@string.documentation"] = { fg = colors.yellow },
    ["@string.escape"] = { fg = colors.pink },
    ["@string.regexp"] = { fg = colors.red },
    ["@string.special"] = { fg = colors.pink },
    ["@symbol"] = { fg = colors.cyan },
    ["@tag"] = { fg = colors.pink },
    ["@tag.attribute"] = { fg = colors.green },
    ["@tag.delimiter"] = { fg = colors.fg },
    ["@text"] = { fg = colors.fg },
    ["@text.danger"] = { fg = colors.red },
    ["@text.emphasis"] = { italic = true },
    ["@text.environment"] = { fg = colors.pink },
    ["@text.environment.name"] = { fg = colors.cyan },
    ["@text.literal"] = { fg = colors.yellow },
    ["@text.math"] = { fg = colors.cyan },
    ["@text.note"] = { fg = colors.cyan },
    ["@text.reference"] = { fg = colors.cyan },
    ["@text.strike"] = { strikethrough = true },
    ["@text.strong"] = { bold = true },
    ["@text.title"] = { fg = colors.purple, bold = true },
    ["@text.todo"] = { fg = colors.orange, bold = true },
    ["@text.underline"] = { underline = true },
    ["@text.uri"] = { fg = colors.cyan, undercurl = true },
    ["@text.warning"] = { fg = colors.orange },
    ["@type"] = { fg = colors.cyan },
    ["@type.builtin"] = { fg = colors.cyan },
    ["@type.definition"] = { fg = colors.cyan },
    ["@type.qualifier"] = { fg = colors.pink },
    ["@variable"] = { fg = colors.fg },
    ["@variable.builtin"] = { fg = colors.purple },

    -- LSP Semantic Token highlights
    ["@lsp.type.boolean"] = { fg = colors.purple },
    ["@lsp.type.builtinType"] = { fg = colors.cyan },
    ["@lsp.type.comment"] = { fg = colors.comment, italic = true },
    ["@lsp.type.decorator"] = { fg = colors.orange },
    ["@lsp.type.deriveHelper"] = { fg = colors.orange },
    ["@lsp.type.enum"] = { fg = colors.cyan },
    ["@lsp.type.enumMember"] = { fg = colors.purple },
    ["@lsp.type.escapeSequence"] = { fg = colors.pink },
    ["@lsp.type.formatSpecifier"] = { fg = colors.pink },
    ["@lsp.type.generic"] = { fg = colors.cyan },
    ["@lsp.type.interface"] = { fg = colors.cyan },
    ["@lsp.type.keyword"] = { fg = colors.pink },
    ["@lsp.type.lifetime"] = { fg = colors.orange },
    ["@lsp.type.namespace"] = { fg = colors.cyan },
    ["@lsp.type.number"] = { fg = colors.purple },
    ["@lsp.type.operator"] = { fg = colors.pink },
    ["@lsp.type.parameter"] = { fg = colors.orange },
    ["@lsp.type.property"] = { fg = colors.orange },
    ["@lsp.type.selfKeyword"] = { fg = colors.purple },
    ["@lsp.type.selfTypeKeyword"] = { fg = colors.purple },
    ["@lsp.type.string"] = { fg = colors.yellow },
    ["@lsp.type.typeAlias"] = { fg = colors.cyan },
    ["@lsp.type.unresolvedReference"] = { fg = colors.red, undercurl = true },
    ["@lsp.type.variable"] = { fg = colors.fg },
    ["@lsp.typemod.class.defaultLibrary"] = { fg = colors.cyan },
    ["@lsp.typemod.enum.defaultLibrary"] = { fg = colors.cyan },
    ["@lsp.typemod.enumMember.defaultLibrary"] = { fg = colors.purple },
    ["@lsp.typemod.function.defaultLibrary"] = { fg = colors.green },
    ["@lsp.typemod.keyword.async"] = { fg = colors.pink },
    ["@lsp.typemod.keyword.injected"] = { fg = colors.pink },
    ["@lsp.typemod.macro.defaultLibrary"] = { fg = colors.green },
    ["@lsp.typemod.method.defaultLibrary"] = { fg = colors.green },
    ["@lsp.typemod.operator.injected"] = { fg = colors.pink },
    ["@lsp.typemod.string.injected"] = { fg = colors.yellow },
    ["@lsp.typemod.struct.defaultLibrary"] = { fg = colors.cyan },
    ["@lsp.typemod.type.defaultLibrary"] = { fg = colors.cyan },
    ["@lsp.typemod.typeAlias.defaultLibrary"] = { fg = colors.cyan },
    ["@lsp.typemod.variable.callable"] = { fg = colors.green },
    ["@lsp.typemod.variable.defaultLibrary"] = { fg = colors.purple },
    ["@lsp.typemod.variable.injected"] = { fg = colors.fg },
    ["@lsp.typemod.variable.static"] = { fg = colors.purple },

    -- Diagnostic highlights
    DiagnosticError = { fg = colors.red },
    DiagnosticWarn = { fg = colors.orange },
    DiagnosticInfo = { fg = colors.cyan },
    DiagnosticHint = { fg = colors.light_gray },
    DiagnosticVirtualTextError = { fg = colors.red, bg = colors.dark_gray },
    DiagnosticVirtualTextWarn = { fg = colors.orange, bg = colors.dark_gray },
    DiagnosticVirtualTextInfo = { fg = colors.cyan, bg = colors.dark_gray },
    DiagnosticVirtualTextHint = { fg = colors.light_gray, bg = colors.dark_gray },
    DiagnosticUnderlineError = { undercurl = true, sp = colors.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = colors.orange },
    DiagnosticUnderlineInfo = { undercurl = true, sp = colors.cyan },
    DiagnosticUnderlineHint = { undercurl = true, sp = colors.light_gray },

    -- Git highlights
    DiffAdd = { fg = colors.green, bg = colors.dark_gray },
    DiffChange = { fg = colors.orange, bg = colors.dark_gray },
    DiffDelete = { fg = colors.red, bg = colors.dark_gray },
    DiffText = { fg = colors.orange, bg = colors.selection },
    GitSignsAdd = { fg = colors.green },
    GitSignsChange = { fg = colors.orange },
    GitSignsDelete = { fg = colors.red },
}

-- Modular highlights for plugins
local integrations = {
    blink_cmp = {
        BlinkCmpMenu = { link = "Pmenu" },
        BlinkCmpMenuBorder = { fg = colors.gray, bg = colors.dark_gray },
        BlinkCmpMenuSelection = { link = "PmenuSel" },
        BlinkCmpLabel = { fg = colors.fg },
        BlinkCmpLabelMatch = { fg = colors.cyan, bold = true },
        BlinkCmpLabelDescription = { fg = colors.light_gray },
        BlinkCmpLabelDetail = { fg = colors.light_gray },
        BlinkCmpKind = { fg = colors.purple },
        BlinkCmpKindText = { fg = colors.fg },
        BlinkCmpKindMethod = { fg = colors.green },
        BlinkCmpKindFunction = { fg = colors.green },
        BlinkCmpKindConstructor = { fg = colors.yellow },
        BlinkCmpKindField = { fg = colors.orange },
        BlinkCmpKindVariable = { fg = colors.purple },
        BlinkCmpKindClass = { fg = colors.cyan },
        BlinkCmpKindInterface = { fg = colors.cyan },
        BlinkCmpKindModule = { fg = colors.cyan },
        BlinkCmpKindProperty = { fg = colors.orange },
        BlinkCmpKindUnit = { fg = colors.purple },
        BlinkCmpKindValue = { fg = colors.purple },
        BlinkCmpKindEnum = { fg = colors.cyan },
        BlinkCmpKindKeyword = { fg = colors.pink },
        BlinkCmpKindSnippet = { fg = colors.yellow },
        BlinkCmpKindColor = { fg = colors.red },
        BlinkCmpKindFile = { fg = colors.yellow },
        BlinkCmpKindReference = { fg = colors.orange },
        BlinkCmpKindFolder = { fg = colors.cyan },
        BlinkCmpKindEnumMember = { fg = colors.purple },
        BlinkCmpKindConstant = { fg = colors.purple },
        BlinkCmpKindStruct = { fg = colors.cyan },
        BlinkCmpKindEvent = { fg = colors.purple },
        BlinkCmpKindOperator = { fg = colors.pink },
        BlinkCmpKindTypeParameter = { fg = colors.cyan },
    },
    neotree = {
        NeoTreeBufferNumber = { fg = colors.purple },
        NeoTreeCursorLine = { bg = colors.gray },
        NeoTreeDimText = { fg = colors.light_gray },
        NeoTreeDirectoryIcon = { fg = colors.cyan },
        NeoTreeDirectoryName = { fg = colors.cyan, bold = true },
        NeoTreeDotfile = { fg = colors.light_gray },
        NeoTreeFileIcon = { fg = colors.fg },
        NeoTreeFileName = { fg = colors.fg },
        NeoTreeFileNameOpened = { fg = colors.green, italic = true },
        NeoTreeFilterTerm = { fg = colors.orange },
        NeoTreeFloatBorder = { fg = colors.purple },
        NeoTreeFloatTitle = { fg = colors.pink, bold = true },
        NeoTreeTitleBar = { fg = colors.pink, bg = colors.bg, bold = true },
        NeoTreeGitAdded = { fg = colors.green },
        NeoTreeGitConflict = { fg = colors.red, bold = true },
        NeoTreeGitDeleted = { fg = colors.red },
        NeoTreeGitIgnored = { fg = colors.light_gray, italic = true },
        NeoTreeGitModified = { fg = colors.yellow },
        NeoTreeGitUnstaged = { fg = colors.orange },
        NeoTreeGitUntracked = { fg = colors.purple },
        NeoTreeGitStaged = { fg = colors.green },
        NeoTreeHiddenByName = { fg = colors.light_gray },
        NeoTreeIndentMarker = { fg = colors.light_gray },
        NeoTreeExpander = { fg = colors.fg },
        NeoTreeNormal = { fg = colors.fg, bg = colors.bg },
        NeoTreeNormalNC = { fg = colors.light_gray, bg = colors.bg },
        NeoTreeSignColumn = { bg = colors.bg },
        NeoTreeStats = { fg = colors.yellow },
        NeoTreeStatsHeader = { fg = colors.pink, bold = true },
        NeoTreeStatusLine = { fg = colors.fg, bg = colors.gray },
        NeoTreeStatusLineNC = { fg = colors.light_gray, bg = colors.gray },
        NeoTreeVertSplit = { fg = colors.gray, bg = colors.bg },
        NeoTreeWinSeparator = { fg = colors.gray, bg = colors.bg },
        NeoTreeEndOfBuffer = { fg = colors.bg },
        NeoTreeRootName = { fg = colors.pink, bold = true },
        NeoTreeSymbolicLinkTarget = { fg = colors.cyan, italic = true },
        NeoTreeWindowsHidden = { fg = colors.light_gray },
    }
}
--
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
