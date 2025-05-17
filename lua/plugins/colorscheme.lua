return {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,

    opts = {
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
    }
}
