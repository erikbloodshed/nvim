-- Treesitter syntax highlighting for Nord theme
local M = {}

function M.get_highlights(palette)
  return {
    -- Comments
    ["@comment"] = { fg = palette.gray5, italic = true },
    ["@comment.documentation"] = { fg = palette.gray5, italic = true },
    ["@comment.error"] = { fg = palette.red.bright, italic = true },
    ["@comment.note"] = { fg = palette.gray5, bold = true, italic = true },
    ["@comment.todo"] = { fg = palette.gray5, bold = true, italic = true },
    ["@comment.warning"] = { fg = palette.yellow.base, italic = true },

    -- Constants and literals
    ["@constant"] = { link = "Constant" },
    ["@constant.builtin"] = { link = "Constant" },
    ["@constant.macro"] = { link = "Constant" },
    ["@character"] = { fg = palette.green.base },
    ["@character.special"] = { fg = palette.blue1 },
    ["@string"] = { fg = palette.green.base },
    ["@string.documentation"] = { fg = palette.green.base },
    ["@string.escape"] = { fg = palette.blue1 },
    ["@string.regexp"] = { fg = palette.red.bright },
    ["@string.special"] = { fg = palette.blue1 },
    ["@float"] = { fg = palette.magenta.base },
    ["@symbol"] = { fg = palette.magenta.base },

    -- Functions and methods
    ["@function"] = { link = "Function" },
    ["@function.builtin"] = { fg = palette.cyan.bright },
    ["@function.call"] = { fg = palette.blue2 },
    ["@function.macro"] = { fg = palette.blue2 },
    ["@method"] = { link = "Function" },
    ["@method.call"] = { link = "Function" },
    ["@constructor"] = { fg = palette.cyan.base },

    -- Variables and parameters
    ["@variable"] = { fg = palette.white0_reduce_blue },
    ["@variable.builtin"] = { fg = palette.magenta.base },
    ["@variable.parameter"] = { link = "@parameter" },
    ["@parameter"] = { fg = palette.orange.base },
    ["@parameter.reference"] = { link = "@parameter" },
    ["@field"] = { fg = palette.orange.base },
    ["@property"] = { fg = palette.white0_normal },

    -- Keywords and control flow
    ["@keyword"] = { link = "Keyword" },
    ["@keyword.function"] = { link = "Keyword" },
    ["@keyword.operator"] = { link = "Keyword" },
    ["@keyword.return"] = { link = "Keyword" },
    ["@conditional"] = { link = "Keyword" },
    ["@repeat"] = { link = "Keyword" },
    ["@label"] = { link = "Keyword" },
    ["@exception"] = { fg = palette.blue1 },

    -- Types and structures
    ["@type"] = { fg = palette.yellow.base },
    ["@type.builtin"] = { fg = palette.yellow.base },
    ["@type.definition"] = { fg = palette.yellow.base },
    ["@type.qualifier"] = { fg = palette.yellow.base },
    ["@storageclass"] = { fg = palette.blue1 },

    -- Operators and punctuation
    ["@operator"] = { link = "Operator" },
    ["@punctuation.bracket"] = { fg = palette.white0_normal },
    ["@punctuation.delimiter"] = { fg = palette.white0_normal },
    ["@punctuation.special"] = { fg = palette.blue1 },

    -- Preprocessor and macros
    ["@preproc"] = { fg = palette.blue1 },
    ["@include"] = { fg = palette.blue1 },
    ["@define"] = { fg = palette.blue1 },
    ["@debug"] = { fg = palette.yellow.base },

    -- Modules and namespaces
    ["@module"] = { fg = palette.cyan.dim },
    ["@namespace"] = { fg = palette.cyan.dim },

    -- Tags (for markup languages)
    ["@tag"] = { fg = palette.blue1 },
    ["@tag.attribute"] = { fg = palette.blue2 },
    ["@tag.delimiter"] = { fg = palette.white0_normal },

    -- Markup elements
    ["@markup.link"] = { fg = palette.cyan.base, underline = true },
    ["@markup.link.url"] = { fg = palette.cyan.base, underline = true },
    ["@markup.heading"] = { fg = palette.magenta.base, bold = true },
    ["@markup.italic"] = { fg = palette.yellow.base, italic = true },
    ["@markup.strong"] = { fg = palette.orange.base, bold = true },
    ["@markup.quote"] = { fg = palette.yellow.base, italic = true },

    -- Text elements (legacy)
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

    -- Miscellaneous
    ["@annotation"] = { fg = palette.yellow.base },
    ["@attribute"] = { fg = palette.blue2 },
    ["@none"] = { fg = palette.white0_normal },
  }
end

return M
