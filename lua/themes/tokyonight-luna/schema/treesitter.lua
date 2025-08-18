local api = vim.api
local blend_bg = require("themes.util").blend_bg
local blend_fg = require("themes.util").blend_fg
local M = {}

M.get = function(c)
  local s = {
  ["@annotation"]                            = { link = "PreProc" },
  ["@attribute"]                             = { link = "PreProc" },
  ["@boolean"]                               = { link = "Boolean" },
  ["@character"]                             = { link = "Character" },
  ["@character.printf"]                      = { link = "SpecialChar" },
  ["@character.special"]                     = { link = "SpecialChar" },
  ["@comment"]                               = { link = "Comment" },
  ["@comment.error"]                         = { fg = c.red },
  ["@comment.hint"]                          = { fg = c.teal },
  ["@comment.info"]                          = { fg = c.blue2 },
  ["@comment.note"]                          = { fg = c.teal },
  ["@comment.todo"]                          = { fg = c.blue },
  ["@comment.warning"]                       = { fg = c.yellow },
  ["@constant"]                              = { link = "Constant" },
  ["@constant.builtin"]                      = { link = "Special" },
  ["@constant.macro"]                        = { link = "Define" },
  ["@constructor"]                           = { fg = c.magenta }, -- For constructor calls and definitions: `= { }` in Lua, and Java constructors.
  ["@constructor.tsx"]                       = { fg = c.blue1 },
  ["@diff.delta"]                            = { link = "DiffChange" },
  ["@diff.minus"]                            = { link = "DiffDelete" },
  ["@diff.plus"]                             = { link = "DiffAdd" },
  ["@function"]                              = { link = "Function" },
  ["@function.builtin"]                      = { link = "Special" },
  ["@function.call"]                         = { link = "Function" },
  ["@function.macro"]                        = { link = "Macro" },
  ["@function.method"]                       = { link = "Function" },
  ["@function.method.call"]                  = { link = "Function" },
  ["@keyword"]                               = { fg = c.purple }, -- For keywords that don't fall in previous categories.
  ["@keyword.conditional"]                   = { link = "Conditional" },
  ["@keyword.coroutine"]                     = { link = "@keyword" },
  ["@keyword.debug"]                         = { link = "Debug" },
  ["@keyword.directive"]                     = { link = "PreProc" },
  ["@keyword.directive.define"]              = { link = "Define" },
  ["@keyword.exception"]                     = { link = "Exception" },
  ["@keyword.function"]                      = { fg = c.magenta }, -- For keywords used to define a function.
  ["@keyword.import"]                        = { link = "Include" },
  ["@keyword.operator"]                      = { link = "@operator" },
  ["@keyword.repeat"]                        = { link = "Repeat" },
  ["@keyword.return"]                        = { link = "@keyword" },
  ["@keyword.storage"]                       = { link = "StorageClass" },
  ["@label"]                                 = { link = "Function" }, -- For labels: `label:` in C and `:label:` in Lua.
  ["@markup"]                                = { link = "@none" },
  ["@markup.emphasis"]                       = { italic = true },
  ["@markup.environment"]                    = { link = "Macro" },
  ["@markup.environment.name"]               = { link = "Type" },
  ["@markup.heading"]                        = { link = "Title" },
  ["@markup.italic"]                         = { italic = true },
  ["@markup.link"]                           = { fg = c.teal },
  ["@markup.link.label"]                     = { link = "SpecialChar" },
  ["@markup.link.label.symbol"]              = { link = "Identifier" },
  ["@markup.link.url"]                       = { link = "Underlined" },
  ["@markup.list"]                           = { fg = c.blue5 },  -- For special punctutation that does not fall in the categories before.
  ["@markup.list.checked"]                   = { fg = c.green1 }, -- For brackets and parens.
  ["@markup.list.markdown"]                  = { fg = c.orange, bold = true },
  ["@markup.list.unchecked"]                 = { fg = c.blue },   -- For brackets and parens.
  ["@markup.math"]                           = { link = "Special" },
  ["@markup.raw"]                            = { link = "String" },
  ["@markup.raw.markdown_inline"]            = { bg = c.bg_dark3, fg = c.blue },
  ["@markup.strikethrough"]                  = { strikethrough = true },
  ["@markup.strong"]                         = { bold = true },
  ["@markup.underline"]                      = { underline = true },
  ["@module"]                                = { link = "Directory" },
  ["@module.builtin"]                        = { fg = c.red }, -- Variable names that are defined by the languages, like `this` or `self`.
  ["@namespace.builtin"]                     = { link = "@variable.builtin" },
  ["@none"]                                  = {},
  ["@number"]                                = { link = "Number" },
  ["@number.float"]                          = { link = "Float" },
  ["@operator"]                              = { link = "Operator" }, -- For any operator: `+`, but also `->` and `*` in C.
  ["@property"]                              = { fg = c.green1 },
  ["@punctuation.bracket"]                   = { fg = c.fg_dark },    -- For brackets and parens.
  ["@punctuation.delimiter"]                 = { fg = c.blue5 },      -- For delimiters ie: `.`
  ["@punctuation.special"]                   = { fg = c.blue5 },      -- For special symbols (e.g. `{}` in string interpolation)
  ["@punctuation.special.markdown"]          = { fg = c.orange },     -- For special symbols (e.g. `{}` in string interpolation)
  ["@string"]                                = { link = "String" },
  ["@string.documentation"]                  = { fg = c.yellow },
  ["@string.escape"]                         = { fg = c.magenta }, -- For escape characters within a string.
  ["@string.regexp"]                         = { fg = c.blue6 },   -- For regexes.
  ["@tag"]                                   = { link = "Label" },
  ["@tag.attribute"]                         = { link = "@property" },
  ["@tag.delimiter"]                         = { link = "Delimiter" },
  ["@tag.delimiter.tsx"]                     = { fg = blend_bg(c.blue, 0.7, c.bg) },
  ["@tag.tsx"]                               = { fg = c.red },
  ["@tag.javascript"]                        = { fg = c.red },
  ["@type"]                                  = { link = "Type" },
  ["@type.builtin"]                          = { fg = blend_bg(c.blue1, 0.8, c.bg) },
  ["@type.definition"]                       = { link = "Typedef" },
  ["@type.qualifier"]                        = { link = "@keyword" },
  ["@variable"]                              = { fg = c.fg },                          -- Any variable name that does not have another highlight.
  ["@variable.builtin"]                      = { fg = c.red },                         -- Variable names that are defined by the languages, like `this` or `self`.
  ["@variable.member"]                       = { fg = c.green1 },                      -- For fields.
  ["@variable.parameter"]                    = { fg = c.yellow },                      -- For parameters of a function.
  ["@variable.parameter.builtin"]            = { fg = blend_fg(c.yellow, 0.8, c.fg) }, -- For builtin parameters of a function, e.g. "..." or Smali's p[1-99]
  }

  ---@format disable-next
  local hl = api.nvim_set_hl
  for key, val in pairs(s) do hl(0, key, val) end
end

return M
