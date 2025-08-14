-- Treesitter syntax highlighting for Ayu Mirage theme
local M = {}

function M.get_highlights(palette)
  return {
    -- Comments
    ["@comment"] = { fg = palette.syntax.comment, italic = true },
    ["@comment.documentation"] = { fg = palette.syntax.comment, italic = true },
    ["@comment.error"] = { fg = palette.common.error, italic = true },
    ["@comment.note"] = { fg = palette.syntax.comment, bold = true, italic = true },
    ["@comment.todo"] = { fg = palette.syntax.markup, bold = true, italic = true },
    ["@comment.warning"] = { fg = palette.syntax.special, italic = true },

    -- Constants and literals
    ["@constant"] = { link = "Constant" },
    ["@constant.builtin"] = { link = "Constant" },
    ["@constant.macro"] = { link = "Constant" },
    ["@character"] = { fg = palette.syntax.string },
    ["@character.special"] = { fg = palette.syntax.entity },
    ["@string"] = { fg = palette.syntax.string },
    ["@string.documentation"] = { fg = palette.syntax.string },
    ["@string.escape"] = { fg = palette.syntax.entity },
    ["@string.regexp"] = { fg = palette.syntax.regexp },
    ["@string.special"] = { fg = palette.syntax.entity },
    ["@float"] = { fg = palette.syntax.constant },
    ["@symbol"] = { fg = palette.syntax.constant },

    -- Functions and methods
    ["@function"] = { link = "Function" },
    ["@function.builtin"] = { fg = palette.syntax.func },
    ["@function.call"] = { fg = palette.syntax.func },
    ["@function.macro"] = { fg = palette.syntax.func },
    ["@method"] = { link = "Function" },
    ["@method.call"] = { link = "Function" },
    ["@constructor"] = { fg = palette.syntax.entity },

    -- Variables and parameters
    ["@variable"] = { fg = palette.editor.fg },
    ["@variable.builtin"] = { fg = palette.syntax.keyword },
    ["@variable.parameter"] = { link = "@parameter" },
    ["@parameter"] = { fg = palette.syntax.operator },
    ["@parameter.reference"] = { link = "@parameter" },
    ["@field"] = { fg = palette.syntax.operator },
    ["@property"] = { fg = palette.editor.fg },

    -- Keywords and control flow
    ["@keyword"] = { link = "Keyword" },
    ["@keyword.function"] = { link = "Keyword" },
    ["@keyword.operator"] = { link = "Keyword" },
    ["@keyword.return"] = { link = "Keyword" },
    ["@conditional"] = { link = "Keyword" },
    ["@repeat"] = { link = "Keyword" },
    ["@label"] = { link = "Keyword" },
    ["@exception"] = { fg = palette.syntax.keyword },

    -- Types and structures
    ["@type"] = { fg = palette.syntax.entity },
    ["@type.builtin"] = { fg = palette.syntax.entity },
    ["@type.definition"] = { fg = palette.syntax.entity },
    ["@type.qualifier"] = { fg = palette.syntax.entity },
    ["@storageclass"] = { fg = palette.syntax.keyword },

    -- Operators and punctuation
    ["@operator"] = { link = "Operator" },
    ["@punctuation.bracket"] = { fg = palette.editor.fg },
    ["@punctuation.delimiter"] = { fg = palette.editor.fg },
    ["@punctuation.special"] = { fg = palette.syntax.special },

    -- Preprocessor and macros
    ["@preproc"] = { fg = palette.syntax.keyword },
    ["@include"] = { fg = palette.syntax.keyword },
    ["@define"] = { fg = palette.syntax.keyword },
    ["@debug"] = { fg = palette.syntax.special },

    -- Modules and namespaces
    ["@module"] = { fg = palette.syntax.tag },
    ["@namespace"] = { fg = palette.syntax.tag },

    -- Tags (for markup languages)
    ["@tag"] = { fg = palette.syntax.tag },
    ["@tag.attribute"] = { fg = palette.syntax.entity },
    ["@tag.delimiter"] = { fg = palette.editor.fg },

    -- Markup elements
    ["@markup.link"] = { fg = palette.syntax.tag, underline = true },
    ["@markup.link.url"] = { fg = palette.syntax.tag, underline = true },
    ["@markup.heading"] = { fg = palette.syntax.markup, bold = true },
    ["@markup.italic"] = { fg = palette.syntax.string, italic = true },
    ["@markup.strong"] = { fg = palette.syntax.operator, bold = true },
    ["@markup.quote"] = { fg = palette.syntax.string, italic = true },

    -- Text elements (legacy)
    ["@text"] = { fg = palette.editor.fg },
    ["@text.danger"] = { fg = palette.common.error, bold = true },
    ["@text.emphasis"] = { fg = palette.syntax.string, italic = true },
    ["@text.environment"] = { fg = palette.syntax.keyword },
    ["@text.environment.name"] = { fg = palette.syntax.tag },
    ["@text.literal"] = { fg = palette.syntax.string },
    ["@text.math"] = { fg = palette.syntax.tag },
    ["@text.note"] = { fg = palette.syntax.tag, bold = true },
    ["@text.reference"] = { fg = palette.syntax.tag },
    ["@text.strike"] = { fg = palette.syntax.comment, strikethrough = true },
    ["@text.strong"] = { fg = palette.syntax.operator, bold = true },
    ["@text.title"] = { fg = palette.syntax.markup, bold = true },
    ["@text.todo"] = { fg = palette.syntax.markup, bold = true },
    ["@text.underline"] = { fg = palette.syntax.tag, underline = true },
    ["@text.uri"] = { fg = palette.syntax.tag, underline = true },
    ["@text.warning"] = { fg = palette.syntax.special, bold = true },

    -- Miscellaneous
    ["@annotation"] = { fg = palette.syntax.special },
    ["@attribute"] = { fg = palette.syntax.entity },
    ["@none"] = { fg = palette.editor.fg },
  }
end

return M
