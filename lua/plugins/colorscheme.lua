return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("tokyonight").setup({
                style = "night",
                transparent = true,
                terminal_colors = true,
                styles = {
                    comments = { italic = true },
                    keywords = { italic = false },
                    functions = { bold = true },
                    variables = {},
                    sidebars = "transparent",
                    floats = "transparent",
                },
                sidebars = {},
                hide_inactive_statusline = true,
                dim_inactive = false,
                lualine_bold = true,
                on_colors = function(colors)
                    colors.border = colors.fg_gutter
                end,
                on_highlights = function(highlights, colors)
                    highlights["@conditional"] = { link = "@keyword" }
                    highlights["@constructor"] = { link = "@function", bold = true }
                    highlights["@keyword.conditional"] = { link = "@keyword" }
                    highlights["@keyword.repeat"] = { link = "@keyword" }
                    highlights["@lsp.type.class"] = {}
                    highlights["@lsp.type.macro"] = {}
                    highlights["@lsp.type.operator"] = {}
                    highlights["@lsp.typemod.class.defaultLibrary"] = { link = "@type" }
                    highlights["@lsp.typemod.function"] = { link = "@function", bold = true }
                    highlights["@lsp.typemod.function.defaultLibrary"] = { link = "@function", bold = true }
                    highlights["@lsp.typemod.method.defaultLibrary"] = { link = "@function", bold = true }
                    highlights["@lsp.typemod.type.defaultLibrary"] = { link = "@type" }
                    highlights["@lsp.typemod.variable.defaultLibrary"] = { link = "@function", bold = true }
                    highlights["@lsp.typemod.variable.static"] = {}
                    highlights["@repeat"] = { link = "@keyword" }
                    highlights["@variable.parameter"] = { fg = colors.red }
                    highlights["NeoTreeRootName"] = { link = "Directory" }
                end,
            })

            -- vim.cmd.colorscheme("tokyonight")
        end
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha", -- latte, frappe, macchiato, mocha
                background = {    -- :h background
                    light = "latte",
                    dark = "mocha",
                },
                transparent_background = true, -- disables setting the background color.
                show_end_of_buffer = false,    -- shows the '~' characters after the end of buffers
                term_colors = true,            -- sets terminal colors (e.g. `g:terminal_color_0`)
                dim_inactive = {
                    enabled = false,           -- dims the background color of inactive window
                    shade = "dark",
                    percentage = 0.15,         -- percentage of the shade to apply to the inactive window
                },
                no_italic = false,             -- Force no italic
                no_bold = false,               -- Force no bold
                no_underline = false,          -- Force no underline
                styles = {                     -- Handles the styles of general hi groups (see `:h highlight-args`):
                    comments = { "italic" },   -- Change the style of comments
                    conditionals = {},
                    loops = {},
                    functions = { "bold" },
                    keywords = {},
                    strings = {},
                    variables = {},
                    numbers = {},
                    booleans = {},
                    properties = {},
                    types = {},
                    operators = {},
                    -- miscs = {}, -- Uncomment to turn off hard-coded styles
                },
                color_overrides = {},
                custom_highlights = {},
                integrations = {
                    native_lsp = {
                        enabled = true,
                        underlines = {
                            errors = { "undercurl" },
                            hints = { "undercurl" },
                            warnings = { "undercurl" },
                            information = { "undercurl" },
                        },
                    },
                }
            })

            -- setup must be called before loading
            vim.cmd.colorscheme "catppuccin"
        end
    }
}
