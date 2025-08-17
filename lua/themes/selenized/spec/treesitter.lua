local p = require("themes.selenized.scheme")

return {
  -- Comments
  ["@comment"] = {},
  ["@comment.documentation"] = {},
  ["@comment.error"] = {},
  ["@comment.note"] = {},
  ["@comment.todo"] = {},
  ["@comment.warning"] = {},

  -- Constants and literals
  ["@constant"] = {},
  ["@constant.builtin"] = {},
  ["@constant.macro"] = {},
  ["@float"] = {},
  ["@symbol"] = {},
  ["@character"] = {},
  ["@character.special"] = {},
  ["@string"] = {},
  ["@string.documentation"] = {},
  ["@string.escape"] = {},
  ["@string.regexp"] = {},
  ["@string.special"] = {},

  -- Functions and methods
  ["@function"] = {},
  ["@function.builtin"] = {},
  ["@function.call"] = {},
  ["@function.macro"] = {},
  ["@method"] = {},
  ["@method.call"] = {},
  ["@constructor"] = {},

  -- Variables and parameters
  ["@variable"] = {},
  ["@variable.builtin"] = {},
  ["@parameter"] = {},
  ["@variable.parameter"] = {},
  ["@parameter.reference"] = {},
  ["@field"] = {},
  ["@property"] = {},

  -- Keywords and control flow
  ["@keyword"] = {},
  ["@keyword.function"] = {},
  ["@keyword.operator"] = {},
  ["@keyword.return"] = {},
  ["@conditional"] = {},
  ["@repeat"] = {},
  ["@label"] = {},
  ["@exception"] = {},

  -- Types and structures
  ["@type"] = {},
  ["@type.builtin"] = {},
  ["@type.definition"] = {},
  ["@type.qualifier"] = {},
  ["@storageclass"] = {},

  -- Operators and punctuation
  ["@operator"] = {},
  ["@punctuation.bracket"] = {},
  ["@punctuation.delimiter"] = {},
  ["@punctuation.special"] = {},

  -- Preprocessor and macros
  ["@preproc"] = {},
  ["@include"] = {},
  ["@define"] = {},
  ["@debug"] = {},

  -- Modules and namespaces
  ["@module"] = {},
  ["@namespace"] = {},

  -- Tags (for markup languages)
  ["@tag"] = {},
  ["@tag.attribute"] = {},
  ["@tag.delimiter"] = {},

  -- Markup elements
  ["@markup.link"] = {},
  ["@markup.link.url"] = {},
  ["@markup.heading"] = {},
  ["@markup.italic"] = {},
  ["@markup.strong"] = {},
  ["@markup.quote"] = {},

  -- Text elements (legacy)
  ["@text"] = {},
  ["@text.danger"] = {},
  ["@text.emphasis"] = {},
  ["@text.environment"] = {},
  ["@text.environment.name"] = {},
  ["@text.literal"] = {},
  ["@text.math"] = {},
  ["@text.note"] = {},
  ["@text.reference"] = {},
  ["@text.strike"] = {},
  ["@text.strong"] = {},
  ["@text.title"] = {},
  ["@text.todo"] = {},
  ["@text.underline"] = {},
  ["@text.uri"] = {},
  ["@text.warning"] = {},

  -- Miscellaneous
  ["@annotation"] = {},
  ["@attribute"] = {},
  ["@none"] = {}
}
