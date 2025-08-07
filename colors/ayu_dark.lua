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

-- Ayu Dark Color Palette structured like OneDark
local colors = {
    -- Core Background Colors (Ayu Dark hierarchy)
    none         = "none",
    bg0          = "#0F1419", -- Main background (Ayu Dark signature)
    bg1          = "#0C0F16", -- Slightly darker background (sidebars, popups)
    bg2          = "#161F26", -- Lighter background (visual selection, current line)
    bg3          = "#4D5566", -- Lightest background (borders, inactive elements)
    bg_d         = "#0B0E14", -- Darker background variant

    -- Core Foreground Colors (Ayu Dark)
    fg           = "#BFBDB6", -- Main foreground text
    light_grey   = "#E6E1CF", -- Primary text (brighter)
    grey         = "#5C6773", -- Secondary text (comments, less important)
    dark_grey    = "#343F4C", -- Tertiary text (line numbers, borders)

    -- Ayu Dark Signature Colors
    red          = "#F07178", -- Errors, delete operations
    dark_red     = "#FF3333", -- Darker red variant
    green        = "#B8CC52", -- Strings, additions, success
    dark_green   = "#98B982", -- Darker green variant
    yellow       = "#E6B673", -- Classes, warnings, constants
    dark_yellow  = "#D19A66", -- Darker yellow/orange variant
    blue         = "#59C2FF", -- Functions, methods, links
    dark_blue    = "#6994BF", -- Darker blue variant (alt_blue)
    purple       = "#D2A6FF", -- Keywords, types, special
    dark_purple  = "#A679D9", -- Darker purple variant
    cyan         = "#95E6CB", -- Operators, escape characters, info
    dark_cyan    = "#4CBB17", -- Darker cyan variant
    orange       = "#F29668", -- Numbers, constants, attributes
    pink         = "#D96C75", -- Pink accent

    -- UI and Special Colors (Ayu Dark)
    cursor_grey  = "#161F26", -- Cursor line background (selection)
    visual_grey  = "#161F26", -- Visual selection background
    menu_grey    = "#151A1E", -- Menu/popup backgrounds (dark_gray)
    special_grey = "#1F2430", -- Special backgrounds (gray)
    gutter_grey  = "#4D5566", -- Gutter, line numbers (ui_gray)
    comment_grey = "#5C6773", -- Comments, inactive text

    -- Git Colors (Ayu Dark Style)
    diff_add     = "#B8CC52", -- Git additions (using green)
    diff_delete  = "#FF3333", -- Git deletions (using red)
    diff_change  = "#E6B673", -- Git modifications (using yellow)
    diff_text    = "#F29668", -- Git diff text highlighting (using orange)
}

-- Main highlight groups following OneDark structure with Ayu Dark colors
local highlights = {
    -- Base highlights
    ColorColumn = { bg = colors.bg2 },
    Cursor = { fg = colors.bg0, bg = colors.fg },
    CursorLine = { bg = colors.cursor_grey },
    CursorColumn = { link = "CursorLine" },
    CursorLineNr = { fg = colors.orange },
    Directory = { fg = colors.blue },
    ErrorMsg = { fg = colors.dark_red },
    FloatBorder = { fg = colors.gutter_grey },
    FoldColumn = { fg = colors.dark_grey, bg = colors.bg0 },
    Folded = { fg = colors.dark_grey, bg = colors.menu_grey },
    Search = { fg = colors.bg0, bg = colors.yellow },
    IncSearch = { link = "Search" },
    LineNr = { fg = colors.gutter_grey },
    ModeMsg = { fg = colors.fg },
    MoreMsg = { fg = colors.green },
    NonText = { fg = colors.gutter_grey },
    Normal = { fg = colors.fg, bg = colors.none },
    NormalFloat = { fg = colors.fg, bg = colors.none },
    Pmenu = { fg = colors.fg, bg = colors.menu_grey },
    PmenuSbar = { bg = colors.special_grey },
    PmenuSel = { fg = colors.bg0, bg = colors.dark_blue, bold = true },
    PmenuThumb = { bg = colors.orange },
    Question = { fg = colors.purple },
    SignColumn = { bg = colors.bg0 },
    SpecialKey = { fg = colors.gutter_grey },
    StatusLine = { fg = colors.fg, bg = colors.special_grey },
    StatusLineNC = { fg = colors.dark_grey, bg = colors.menu_grey },
    TabLine = { fg = colors.dark_grey, bg = colors.menu_grey },
    TabLineFill = { link = "TabLine" },
    TabLineSel = { fg = colors.fg, bg = colors.bg0 },
    Title = { fg = colors.bg0, bg = colors.blue, bold = true },
    VertSplit = { fg = colors.gutter_grey },
    WinSeparator = { link = "VertSplit" },
    Visual = { bg = colors.visual_grey },
    VisualNOS = { link = "Visual" },
    WarningMsg = { fg = colors.yellow },
    Whitespace = { fg = colors.gutter_grey },
    EndOfBuffer = { fg = colors.bg0 },
    WildMenu = { fg = colors.bg0, bg = colors.orange },
    QuickFixLine = { bg = colors.visual_grey },
    MatchParen = { fg = colors.orange, bold = true },

    -- Syntax highlighting (Ayu Dark style)
    Boolean = { fg = colors.orange },
    Character = { fg = colors.yellow },
    Comment = { fg = colors.comment_grey, italic = true },
    Conditional = { fg = colors.orange },
    Constant = { fg = colors.orange },
    Debug = { fg = colors.red },
    Define = { fg = colors.orange },
    Delimiter = { fg = colors.fg },
    Error = { fg = colors.red },
    Exception = { fg = colors.orange },
    Float = { fg = colors.purple },
    Function = { fg = colors.blue },
    Identifier = { fg = colors.fg },
    Ignore = { fg = colors.gutter_grey },
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
    SpecialComment = { fg = colors.dark_grey },
    Statement = { fg = colors.orange },
    StorageClass = { fg = colors.orange },
    String = { fg = colors.green },
    Structure = { fg = colors.yellow },
    Tag = { fg = colors.orange },
    Todo = { fg = colors.yellow, bold = true },
    Type = { fg = colors.yellow },
    Typedef = { fg = colors.yellow },
    Underlined = { fg = colors.cyan, underline = true },

    -- Treesitter highlights (Ayu Dark mappings)
    ["@annotation"] = { fg = colors.yellow },
    ["@attribute"] = { fg = colors.yellow },
    ["@boolean"] = { fg = colors.orange },
    ["@character"] = { fg = colors.orange },
    ["@character.special"] = { fg = colors.orange },
    ["@comment"] = { fg = colors.comment_grey, italic = true },
    ["@comment.documentation"] = { fg = colors.dark_grey },
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
    ["@function"] = { fg = colors.blue },
    ["@function.builtin"] = { fg = colors.blue },
    ["@function.call"] = { fg = colors.blue },
    ["@function.macro"] = { fg = colors.blue },
    ["@include"] = { fg = colors.orange },
    ["@keyword"] = { link = "Keyword" },
    ["@keyword.function"] = { link = "Keyword" },
    ["@keyword.operator"] = { link = "Keyword" },
    ["@keyword.return"] = { link = "Keyword" },
    ["@label"] = { fg = colors.orange },
    ["@markup.link"] = { fg = colors.blue },
    ["@method"] = { fg = colors.blue },
    ["@method.call"] = { fg = colors.blue },
    ["@namespace"] = { fg = colors.yellow },
    ["@none"] = { fg = colors.fg },
    ["@number"] = { link = "Number" },
    ["@operator"] = { link = "Keyword" },
    ["@parameter"] = { fg = colors.red },
    ["@parameter.reference"] = { fg = colors.fg },
    ["@preproc"] = { fg = colors.orange },
    ["@property"] = { fg = colors.blue },
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
    ["@tag.attribute"] = { fg = colors.blue },
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

    -- Diagnostic highlights (Ayu Dark style)
    DiagnosticError = { fg = colors.dark_red },
    DiagnosticWarn = { fg = colors.dark_yellow },
    DiagnosticInfo = { fg = colors.dark_blue },
    DiagnosticHint = { fg = colors.dark_grey },
    DiagnosticVirtualTextError = { fg = colors.red, bg = colors.menu_grey },
    DiagnosticVirtualTextWarn = { fg = colors.yellow, bg = colors.menu_grey },
    DiagnosticVirtualTextInfo = { fg = colors.blue, bg = colors.menu_grey },
    DiagnosticVirtualTextHint = { fg = colors.dark_grey, bg = colors.menu_grey },
    DiagnosticUnderlineError = { undercurl = true, sp = colors.dark_red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = colors.dark_yellow },
    DiagnosticUnderlineInfo = { undercurl = true, sp = colors.dark_blue },
    DiagnosticUnderlineHint = { undercurl = true, sp = colors.dark_grey },

    -- Git highlights (Ayu Dark style)
    DiffAdd = { fg = colors.green, bg = colors.menu_grey },
    DiffChange = { fg = colors.yellow, bg = colors.menu_grey },
    DiffDelete = { fg = colors.red, bg = colors.menu_grey },
    DiffText = { fg = colors.yellow, bg = colors.bg2 },
    GitSignsAdd = { fg = colors.green },
    GitSignsChange = { fg = colors.yellow },
    GitSignsDelete = { fg = colors.red },
}

-- Modular highlights for plugins (Ayu Dark colors)
local integrations = {
    blink_cmp = {
        BlinkCmpMenu = { link = "Pmenu" },
        BlinkCmpMenuBorder = { fg = colors.gutter_grey, bg = colors.menu_grey },
        BlinkCmpMenuSelection = { link = "PmenuSel" },
        BlinkCmpLabel = { fg = colors.fg },
        BlinkCmpLabelMatch = { fg = colors.yellow, bold = true },
        BlinkCmpLabelDescription = { fg = colors.dark_grey },
        BlinkCmpLabelDetail = { fg = colors.dark_grey },
        BlinkCmpKind = { fg = colors.orange },
        BlinkCmpKindText = { fg = colors.fg },
        BlinkCmpKindMethod = { fg = colors.blue },
        BlinkCmpKindFunction = { fg = colors.blue },
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
        NeoTreeCursorLine = { bg = colors.special_grey },
        NeoTreeDimText = { fg = colors.dark_grey },
        NeoTreeDirectoryIcon = { link = "Directory" },
        NeoTreeDirectoryName = { link = "Directory", bold = true },
        NeoTreeDotfile = { fg = colors.dark_grey },
        NeoTreeFileIcon = { fg = colors.fg },
        NeoTreeFileName = { fg = colors.fg },
        NeoTreeFileNameOpened = { fg = colors.blue, italic = true },
        NeoTreeFilterTerm = { fg = colors.blue },
        NeoTreeFloatBorder = { fg = colors.orange },
        NeoTreeFloatTitle = { fg = colors.orange, bold = true },
        NeoTreeTitleBar = { fg = colors.orange, bg = colors.bg0, bold = true },
        NeoTreeGitAdded = { fg = colors.green },
        NeoTreeGitConflict = { fg = colors.red, bold = true },
        NeoTreeGitDeleted = { fg = colors.red },
        NeoTreeGitIgnored = { fg = colors.dark_grey, italic = true },
        NeoTreeGitModified = { fg = colors.yellow },
        NeoTreeGitUnstaged = { fg = colors.yellow },
        NeoTreeGitUntracked = { fg = colors.orange },
        NeoTreeGitStaged = { fg = colors.green },
        NeoTreeHiddenByName = { fg = colors.dark_grey },
        NeoTreeIndentMarker = { fg = colors.dark_grey },
        NeoTreeExpander = { fg = colors.fg },
        NeoTreeNormal = { fg = colors.fg, bg = colors.none },
        NeoTreeNormalNC = { fg = colors.dark_grey, bg = colors.none },
        NeoTreeSignColumn = { bg = colors.bg0 },
        NeoTreeStats = { fg = colors.green },
        NeoTreeStatsHeader = { fg = colors.orange, bold = true },
        NeoTreeStatusLine = { fg = colors.fg, bg = colors.special_grey },
        NeoTreeStatusLineNC = { fg = colors.dark_grey, bg = colors.special_grey },
        NeoTreeVertSplit = { fg = colors.gutter_grey, bg = colors.bg0 },
        NeoTreeWinSeparator = { fg = colors.gutter_grey, bg = colors.bg0 },
        NeoTreeEndOfBuffer = { fg = colors.bg0 },
        NeoTreeRootName = { fg = colors.orange, bold = true },
        NeoTreeSymbolicLinkTarget = { fg = colors.cyan, italic = true },
        NeoTreeWindowsHidden = { fg = colors.dark_grey },
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

-- Terminal colors (Ayu Dark 16-color palette)
vim.g.terminal_color_0  = colors.bg0        -- black
vim.g.terminal_color_1  = colors.red        -- red
vim.g.terminal_color_2  = colors.green      -- green
vim.g.terminal_color_3  = colors.yellow     -- yellow
vim.g.terminal_color_4  = colors.blue       -- blue
vim.g.terminal_color_5  = colors.purple     -- magenta
vim.g.terminal_color_6  = colors.cyan       -- cyan
vim.g.terminal_color_7  = colors.fg         -- white
vim.g.terminal_color_8  = colors.grey       -- bright black
vim.g.terminal_color_9  = colors.red        -- bright red
vim.g.terminal_color_10 = colors.green      -- bright green
vim.g.terminal_color_11 = colors.yellow     -- bright yellow
vim.g.terminal_color_12 = colors.blue       -- bright blue
vim.g.terminal_color_13 = colors.purple     -- bright magenta
vim.g.terminal_color_14 = colors.cyan       -- bright cyan
vim.g.terminal_color_15 = colors.light_grey -- bright white

local boost             = {
    { treesitter = "variable.builtin",  priority = 126 },
}

-- Update certain tokens to use a highlight of a higher priority
vim.api.nvim_create_autocmd("LspTokenUpdate", {
    callback = function(args)
        local token = args.data.token
        local captures = vim.treesitter.get_captures_at_pos(args.buf, token.line, token.start_col)

        for _, t in pairs(boost) do
            local priority = t.priority
            if t.treesitter then
                for _, capture in pairs(captures) do
                    if capture.capture == t.treesitter then
                        vim.lsp.semantic_tokens.highlight_token(
                            token,
                            args.buf,
                            args.data.client_id,
                            "@" .. t.treesitter,
                            { priority = priority }
                        )
                    end
                end
            end
        end
    end,
})
