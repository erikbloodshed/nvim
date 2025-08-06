-- Ayu Dark Colorscheme for Neovim
-- File: lua/ayu-dark/init.lua
-- Refactored for better configuration and maintainability

local M = {}

--[[
  ==============================================================================
   1. Configuration
  ==============================================================================
   - `defaults` contains all the default settings.
   - Users can override any of these settings by passing a table to the
     `setup()` function.
]]

local defaults = {
    -- You can add options here to make your colorscheme configurable.
    -- For example, allowing users to disable italics.
    italic_comments = true,
    italic_keywords = true,

    -- The entire color palette is overrideable.
    colors = {
        -- Base colors (Ayu Dark)
        bg = "#0f1419",
        bg_dark = "#0d1016",
        bg_light = "#1f2430",
        bg_lighter = "#272d38",
        fg = "#bfbdb6",
        fg_dark = "#5c6773",
        fg_light = "#e6e1cf",

        -- Ayu accent colors
        blue = "#59c2ff",
        blue_dark = "#399ee6",
        cyan = "#95e6cb",
        green = "#aad94c",
        yellow = "#ffb454",
        orange = "#ff8f40",
        red = "#f07178",
        purple = "#d2a6ff",
        magenta = "#ff7edb",

        -- UI colors
        border = "#1e2328",
        selection = "#253340",
        search = "#ffcc66",
        match = "#f2cc60",

        -- Git colors (Ayu specific)
        git_add = "#91b362",
        git_change = "#e6b450",
        git_delete = "#d96c75",

        -- Diagnostic colors
        error = "#f07178",
        warning = "#ffb454",
        info = "#59c2ff",
        hint = "#5c6773",

        -- Special
        none = "NONE",
    },
}

-- Deep merge utility for combining user config with defaults.
local function merge(base, new)
    for k, v in pairs(new) do
        if type(v) == "table" and type(base[k]) == "table" then
            base[k] = merge(base[k], v)
        else
            base[k] = v
        end
    end
    return base
end


--[[
  ==============================================================================
   2. Highlight Definitions
  ==============================================================================
   - The `highlights.apply()` function sets all the highlight groups.
   - It is organized into logical sections for readability.
]]

local highlights = {}

-- Helper function to reduce boilerplate
local function hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

-- The main function to apply all highlights
function highlights.apply(config)
    local c = config.colors -- Use the final, merged colors
    vim.g.colors_name = "ayu-dark"
    vim.o.termguicolors = true

    -- Clear existing highlights for a clean slate
    vim.cmd("hi clear")
    if vim.fn.exists("syntax_on") then
        vim.cmd("syntax reset")
    end

    -- Configurable styles
    local comment_style = { fg = c.fg_dark, italic = config.italic_comments }
    local keyword_style = { fg = c.purple, italic = config.italic_keywords }

    -- ==========================================================================
    -- A. Base UI Highlights
    -- ==========================================================================
    hl("Normal", { fg = c.fg, bg = c.bg })
    hl("NormalFloat", { fg = c.fg, bg = c.bg_light })
    hl("NormalNC", { fg = c.fg_dark, bg = c.bg })
    hl("LineNr", { fg = c.fg_dark })
    hl("CursorLineNr", { fg = c.blue, bold = true })
    hl("CursorLine", { bg = c.bg_light })
    hl("CursorColumn", { bg = c.bg_light })
    hl("ColorColumn", { bg = c.bg_light })
    hl("SignColumn", { bg = c.bg })
    hl("Folded", { fg = c.fg_dark, bg = c.bg_light })
    hl("FoldColumn", { fg = c.fg_dark, bg = c.bg })
    hl("VertSplit", { fg = c.border })
    hl("WinSeparator", { fg = c.border })
    hl("StatusLine", { fg = c.fg, bg = c.bg_lighter })
    hl("StatusLineNC", { fg = c.fg_dark, bg = c.bg_light })
    hl("Tabline", { fg = c.fg_dark, bg = c.bg_light })
    hl("TablineFill", { bg = c.bg_light })
    hl("TablineSel", { fg = c.fg_light, bg = c.bg_lighter })
    hl("Visual", { bg = c.selection })
    hl("VisualNOS", { bg = c.selection })
    hl("Search", { fg = c.bg, bg = c.search })
    hl("IncSearch", { fg = c.bg, bg = c.match })
    hl("CurSearch", { fg = c.bg, bg = c.orange })
    hl("Pmenu", { fg = c.fg, bg = c.bg_lighter })
    hl("PmenuSel", { fg = c.fg_light, bg = c.blue_dark })
    hl("PmenuSbar", { bg = c.bg_lighter })
    hl("PmenuThumb", { bg = c.border })
    hl("ErrorMsg", { fg = c.error, bold = true })
    hl("WarningMsg", { fg = c.warning, bold = true })
    hl("ModeMsg", { fg = c.fg, bold = true })
    hl("MoreMsg", { fg = c.green, bold = true })
    hl("Underlined", { underline = true })
    hl("Ignore", { fg = c.fg_dark })
    hl("Error", { fg = c.error, bg = c.bg_light })
    hl("Todo", { fg = c.yellow, bold = true })

    -- ==========================================================================
    -- B. Syntax Highlights
    -- ==========================================================================
    hl("Comment", comment_style)
    hl("Constant", { fg = c.orange })
    hl("String", { fg = c.green })
    hl("Character", { fg = c.green })
    hl("Number", { fg = c.orange })
    hl("Boolean", { fg = c.orange })
    hl("Float", { fg = c.orange })
    hl("Identifier", { fg = c.fg })
    hl("Function", { fg = c.yellow })
    hl("Statement", keyword_style)
    hl("Conditional", keyword_style)
    hl("Repeat", keyword_style)
    hl("Label", keyword_style)
    hl("Operator", { fg = c.orange })
    hl("Keyword", keyword_style)
    hl("Exception", keyword_style)
    hl("PreProc", { fg = c.blue })
    hl("Include", { fg = c.blue })
    hl("Define", { fg = c.blue })
    hl("Macro", { fg = c.blue })
    hl("PreCondit", { fg = c.blue })
    hl("Type", { fg = c.cyan })
    hl("StorageClass", keyword_style)
    hl("Structure", { fg = c.cyan })
    hl("Typedef", { fg = c.cyan })
    hl("Special", { fg = c.red })
    hl("Tag", { fg = c.blue })

    -- ==========================================================================
    -- C. Treesitter Highlights
    -- ==========================================================================
    hl("@variable", { fg = c.fg })
    hl("@variable.builtin", { fg = c.red })
    hl("@constant", { fg = c.orange })
    hl("@module", { fg = c.blue })
    hl("@string", { fg = c.green })
    hl("@string.regexp", { fg = c.cyan })
    hl("@string.escape", { fg = c.orange })
    hl("@number", { fg = c.orange })
    hl("@boolean", { fg = c.orange })
    hl("@type", { fg = c.cyan })
    hl("@function", { fg = c.yellow })
    hl("@function.builtin", { fg = c.yellow })
    hl("@function.call", { fg = c.yellow })
    hl("@function.macro", { fg = c.blue })
    hl("@constructor", { fg = c.cyan })
    hl("@operator", { fg = c.orange })
    hl("@keyword", keyword_style)
    hl("@keyword.function", keyword_style)
    hl("@keyword.import", { fg = c.blue })
    hl("@keyword.return", keyword_style)
    hl("@punctuation.delimiter", { fg = c.fg })
    hl("@punctuation.bracket", { fg = c.fg })
    hl("@punctuation.special", { fg = c.magenta })
    hl("@comment", comment_style)
    hl("@comment.documentation", comment_style)
    hl("@comment.error", { fg = c.error, italic = config.italic_comments })
    hl("@comment.warning", { fg = c.warning, italic = config.italic_comments })
    hl("@comment.todo", { fg = c.yellow, bold = true, italic = config.italic_comments })
    hl("@comment.note", { fg = c.info, italic = config.italic_comments })
    hl("@markup.strong", { bold = true })
    hl("@markup.italic", { italic = true })
    hl("@markup.heading", { fg = c.blue, bold = true })
    hl("@markup.link.url", { fg = c.blue, underline = true })
    hl("@markup.raw", { fg = c.cyan })
    hl("@diff.plus", { fg = c.git_add })
    hl("@diff.minus", { fg = c.git_delete })
    hl("@diff.delta", { fg = c.git_change })
    hl("@tag", { fg = c.blue })
    hl("@tag.attribute", { fg = c.yellow })
    hl("@tag.delimiter", { fg = c.fg_dark })

    -- ==========================================================================
    -- D. Diagnostics
    -- ==========================================================================
    hl("DiagnosticError", { fg = c.error })
    hl("DiagnosticWarn", { fg = c.warning })
    hl("DiagnosticInfo", { fg = c.info })
    hl("DiagnosticHint", { fg = c.hint })
    hl("DiagnosticUnderlineError", { undercurl = true, sp = c.error })
    hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.warning })
    hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.info })
    hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.hint })

    -- ==========================================================================
    -- E. Plugin Highlights
    -- ==========================================================================
    -- GitSigns
    hl("GitSignsAdd", { fg = c.git_add })
    hl("GitSignsChange", { fg = c.git_change })
    hl("GitSignsDelete", { fg = c.git_delete })

    -- Lualine
    hl("lualine_a_normal", { fg = c.bg, bg = c.blue, bold = true })
    hl("lualine_b_normal", { fg = c.fg, bg = c.bg_lighter })
    hl("lualine_c_normal", { fg = c.fg_dark, bg = c.bg_light })
    -- ... add other lualine modes if needed ...

    -- Neo-tree
    hl("NeoTreeNormal", { fg = c.fg, bg = c.bg_dark })
    hl("NeoTreeNormalNC", { fg = c.fg, bg = c.bg_dark })
    hl("NeoTreeRootName", { fg = c.blue, bold = true })
    hl("NeoTreeDirectoryName", { fg = c.blue })
    hl("NeoTreeGitModified", { fg = c.git_change })

    -- Add other plugins here...
end

--[[
  ==============================================================================
   3. Public API
  ==============================================================================
]]

-- The main setup function, called by the user.
function M.setup(opts)
    -- 1. Merge user-provided options with the defaults
    local config = merge(defaults, opts or {})

    -- 2. Apply all highlights using the final configuration
    highlights.apply(config)
end

-- A convenience function to load the colorscheme, e.g. for a `:colorscheme` command.
function M.load()
    M.setup()
end

-- Autocommand to reload the colorscheme when `:colorscheme ayu-dark` is used.
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "ayu-dark",
    callback = function()
        M.load()
    end,
})

return M
