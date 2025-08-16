local M = {}

function M.get_highlights(p)
  return {
    -- Comments
    ["@comment"] = { fg = p.syntax.comment, italic = true },
    ["@comment.documentation"] = { fg = p.syntax.comment, italic = true },
    ["@comment.error"] = { fg = p.common.error, italic = true },
    ["@comment.note"] = { fg = p.syntax.comment, bold = true, italic = true },
    ["@comment.todo"] = { fg = p.syntax.entity, bold = true, italic = true },
    ["@comment.warning"] = { fg = p.syntax.special, italic = true },

    -- Constants and literals
    ["@constant"] = { fg = p.syntax.constant },
    ["@constant.builtin"] = { link = "@constant" },
    ["@constant.macro"] = { link = "@constant" },
    ["@float"] = { link = "@constant" },
    ["@symbol"] = { link = "@constant" },
    ["@character"] = { fg = p.syntax.string },
    ["@character.special"] = { fg = p.syntax.entity },
    ["@string"] = { fg = p.syntax.string },
    ["@string.documentation"] = { link = "@string" },
    ["@string.escape"] = { link = "@constant" },
    ["@string.regexp"] = { fg = p.syntax.regexp },
    ["@string.special"] = { fg = p.syntax.special },

    -- Functions and methods
    ["@function"] = { fg = p.syntax.func },
    ["@function.builtin"] = { link = "@function" },
    ["@function.call"] = { link = "@function" },
    ["@function.macro"] = { link = "@function" },
    ["@method"] = { link = "@function" },
    ["@method.call"] = { link = "@function" },
    ["@constructor"] = { link = "@function" },

    -- Variables and parameters
    ["@variable"] = { fg = p.editor.fg },
    ["@variable.builtin"] = { fg = p.syntax.keyword, italic = true },
    ["@parameter"] = { link = "@constant" },
    ["@variable.parameter"] = { link = "@parameter" },
    ["@parameter.reference"] = { link = "@parameter" },
    ["@field"] = { link = "@variable" },
    ["@property"] = { link = "@variable" },

    -- Keywords and control flow
    ["@keyword"] = { fg = p.syntax.keyword },
    ["@keyword.function"] = { link = "@keyword" },
    ["@keyword.operator"] = { link = "@keyword" },
    ["@keyword.return"] = { link = "@keyword" },
    ["@conditional"] = { link = "@keyword" },
    ["@repeat"] = { link = "@keyword" },
    ["@label"] = { link = "@keyword" },
    ["@exception"] = { link = "@keyword" },

    -- Types and structures
    ["@type"] = { fg = p.syntax.entity },
    ["@type.builtin"] = { link = "@type" },
    ["@type.definition"] = { link = "@type" },
    ["@type.qualifier"] = { link = "@type" },
    ["@storageclass"] = { link = "@type" },

    -- Operators and punctuation
    ["@operator"] = { fg = p.syntax.operator },
    ["@punctuation.bracket"] = { fg = p.editor.fg },
    ["@punctuation.delimiter"] = { fg = p.editor.fg },
    ["@punctuation.special"] = { fg = p.syntax.special },

    -- Preprocessor and macros
    ["@preproc"] = { fg = p.syntax.keyword },
    ["@include"] = { fg = p.syntax.keyword },
    ["@define"] = { fg = p.syntax.keyword },
    ["@debug"] = { fg = p.syntax.special },

    -- Modules and namespaces
    ["@module"] = { fg = p.syntax.tag },
    ["@namespace"] = { fg = p.syntax.tag },

    -- Tags (for markup languages)
    ["@tag"] = { fg = p.syntax.tag },
    ["@tag.attribute"] = { fg = p.syntax.entity },
    ["@tag.delimiter"] = { fg = p.editor.fg },

    -- Markup elements
    ["@markup.link"] = { fg = p.syntax.tag, underline = true },
    ["@markup.link.url"] = { fg = p.syntax.tag, underline = true },
    ["@markup.heading"] = { fg = p.syntax.markup, bold = true },
    ["@markup.italic"] = { fg = p.syntax.string, italic = true },
    ["@markup.strong"] = { fg = p.syntax.operator, bold = true },
    ["@markup.quote"] = { fg = p.syntax.string, italic = true },

    -- Text elements (legacy)
    ["@text"] = { fg = p.editor.fg },
    ["@text.danger"] = { fg = p.common.error, bold = true },
    ["@text.emphasis"] = { fg = p.syntax.string, italic = true },
    ["@text.environment"] = { fg = p.syntax.keyword },
    ["@text.environment.name"] = { fg = p.syntax.tag },
    ["@text.literal"] = { fg = p.syntax.string },
    ["@text.math"] = { fg = p.syntax.tag },
    ["@text.note"] = { fg = p.syntax.tag, bold = true },
    ["@text.reference"] = { fg = p.syntax.tag },
    ["@text.strike"] = { fg = p.syntax.comment, strikethrough = true },
    ["@text.strong"] = { fg = p.syntax.operator, bold = true },
    ["@text.title"] = { fg = p.syntax.markup, bold = true },
    ["@text.todo"] = { fg = p.syntax.markup, bold = true },
    ["@text.underline"] = { fg = p.syntax.tag, underline = true },
    ["@text.uri"] = { fg = p.syntax.tag, underline = true },
    ["@text.warning"] = { fg = p.syntax.special, bold = true },

    -- Miscellaneous
    ["@annotation"] = { fg = p.syntax.special },
    ["@attribute"] = { fg = p.syntax.entity },
    ["@none"] = { fg = p.editor.fg },
  }
end

return M
