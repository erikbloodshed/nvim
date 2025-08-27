local M = {}

function M.get(c)
  local colors = {                                    -- Reference: https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md
    -- Identifiers
    ["@variable"] = { fg = c.text },                  -- Any variable name that does not have another highlight.
    ["@variable.builtin"] = { fg = c.red },           -- Variable names that are defined by the languages, like this or self.
    ["@variable.parameter"] = { fg = c.maroon },      -- For parameters of a function.
    ["@variable.member"] = { fg = c.lavender },       -- For fields.

    ["@constant"] = { link = "Constant" },            -- For constants
    ["@constant.builtin"] = { link = "Constant" },    -- For constant that are built in the language: nil in Lua.
    ["@constant.macro"] = { link = "Macro" },         -- For constants that are defined by macros: NULL in C.

    ["@module"] = { fg = c.lavender, italic = true }, -- For identifiers referring to modules and namespaces.
    ["@label"] = { link = "Label" },                  -- For labels: label: in C and :label: in Lua.

    -- Literals
    ["@string"] = { link = "String" },                                               -- For strings.
    ["@string.documentation"] = { fg = c.teal },                                     -- For strings documenting code (e.g. Python docstrings).
    ["@string.regexp"] = { link = "Constant" },                                      -- For regexes.
    ["@string.escape"] = { link = "Special" },                                       -- For escape characters within a string.
    ["@string.special"] = { link = "Special" },                                      -- other special strings (e.g. dates)
    ["@string.special.path"] = { link = "Special" },                                 -- filenames
    ["@string.special.symbol"] = { link = "Identifier" },                            -- symbols or atoms
    ["@string.special.url"] = { fg = c.rosewater, italic = true, underline = true }, -- urls, links and emails

    ["@character"] = { link = "Character" },                                         -- character literals
    ["@character.special"] = { link = "SpecialChar" },                               -- special characters (e.g. wildcards)

    ["@boolean"] = { link = "Constant" },                                            -- For booleans.
    ["@number"] = { link = "Constant" },                                             -- For all numbers
    ["@number.float"] = { link = "Constant" },                                       -- For floats.

    -- Types
    ["@type"] = { link = "StorageClass" },            -- For types.
    ["@type.builtin"] = { link = "StorageClass" },    -- For builtin types.
    ["@type.definition"] = { link = "StorageClass" }, -- type definitions (e.g. `typedef` in C)

    ["@attribute"] = { link = "Constant" },           -- attribute annotations (e.g. Python decorators)
    ["@property"] = { link = "@variable.member" },    -- Same as TSField.

    -- Functions
    ["@function"] = { link = "Function" },             -- For function (calls and definitions).
    ["@function.builtin"] = { link = "Constant" },     -- For builtin functions: table.insert in Lua.
    ["@function.call"] = { link = "Function" },        -- function calls
    ["@function.macro"] = { fg = c.teal },             -- For macro defined functions (calls and definitions): each macro_rules in Rust.

    ["@function.method"] = { link = "Function" },      -- For method definitions.
    ["@function.method.call"] = { link = "Function" }, -- For method calls.

    ["@constructor"] = { fg = c.sapphire },            -- For constructor calls and definitions: = { } in Lua, and Java constructors.
    ["@operator"] = { link = "Operator" },             -- For any operator: +, but also -> and * in C.

    -- Keywords
    ["@keyword"] = { link = "Statement" },                    -- For keywords that don't fall in previous categories.
    ["@keyword.modifier"] = { link = "Statement" },           -- For keywords modifying other constructs (e.g. `const`, `static`, `public`)
    ["@keyword.type"] = { link = "Statement" },               -- For keywords describing composite types (e.g. `struct`, `enum`)
    ["@keyword.coroutine"] = { link = "Statement" },          -- For keywords related to coroutines (e.g. `go` in Go, `async/await` in Python)
    ["@keyword.function"] = { link = "Statement" },           -- For keywords used to define a function.
    ["@keyword.operator"] = { link = "Operator" },            -- For new keyword operator
    ["@keyword.import"] = { link = "Include" },               -- For includes: #include in C, use or extern crate in Rust, or require in Lua.
    ["@keyword.repeat"] = { link = "Statement" },             -- For keywords related to loops.
    ["@keyword.return"] = { link = "Statement" },
    ["@keyword.debug"] = { link = "Statement" },              -- For keywords related to debugging
    ["@keyword.exception"] = { link = "Statement" },          -- For exception related keywords.

    ["@keyword.conditional"] = { link = "Statement" },        -- For keywords related to conditionnals.
    ["@keyword.conditional.ternary"] = { link = "Operator" }, -- For ternary operators (e.g. `?` / `:`)

    ["@keyword.directive"] = { link = "PreProc" },            -- various preprocessor directives & shebangs
    ["@keyword.directive.define"] = { link = "Define" },      -- preprocessor definition directives
    -- JS & derivative
    ["@keyword.export"] = { link = "Operator" },

    -- Punctuation
    ["@punctuation.delimiter"] = { link = "Delimiter" }, -- For delimiters (e.g. `;` / `.` / `,`).
    ["@punctuation.bracket"] = { link = "Delimiter" },   -- For brackets and parenthesis.
    ["@punctuation.special"] = { link = "Special" },     -- For special punctuation that does not fall in the categories before (e.g. `{}` in string interpolation).

    -- Comment
    ["@comment"] = { link = "Comment" },
    ["@comment.documentation"] = { link = "Comment" }, -- For comments documenting code

    ["@comment.error"] = { fg = c.base, bg = c.red },
    ["@comment.warning"] = { fg = c.base, bg = c.yellow },
    ["@comment.hint"] = { fg = c.base, bg = c.blue },
    ["@comment.todo"] = { fg = c.base, bg = c.flamingo },
    ["@comment.note"] = { fg = c.base, bg = c.rosewater },

    -- Markup
    ["@markup"] = { fg = c.text },                                                -- For strings considerated text in a markup language.
    ["@markup.strong"] = { fg = c.maroon, bold = true },                          -- bold
    ["@markup.italic"] = { fg = c.maroon, italic = true },                        -- italic
    ["@markup.strikethrough"] = { fg = c.text, strikethrough = true },            -- strikethrough text
    ["@markup.underline"] = { link = "Underlined" },                              -- underlined text

    ["@markup.heading"] = { fg = c.blue, bold = true },                           -- titles like: # Example

    ["@markup.math"] = { fg = c.blue },                                           -- math environments (e.g. `$ ... $` in LaTeX)
    ["@markup.quote"] = { fg = c.maroon, bold = true },                           -- block quotes
    ["@markup.environment"] = { fg = c.pink },                                    -- text environments of markup languages
    ["@markup.environment.name"] = { fg = c.blue },                               -- text indicating the type of an environment

    ["@markup.link"] = { link = "Tag" },                                          -- text references, footnotes, citations, etc.
    ["@markup.link.label"] = { link = "Label" },                                  -- link, reference descriptions
    ["@markup.link.url"] = { fg = c.rosewater, italic = true, underline = true }, -- urls, links and emails

    ["@markup.raw"] = { fg = c.teal },                                            -- used for inline code in markdown and for doc in python (""")

    ["@markup.list"] = { link = "Special" },
    ["@markup.list.checked"] = { fg = c.green },      -- todo notes
    ["@markup.list.unchecked"] = { fg = c.overlay1 }, -- todo notes

    -- Diff
    ["@diff.plus"] = { link = "diffAdded" },    -- added text (for diff files)
    ["@diff.minus"] = { link = "diffRemoved" }, -- deleted text (for diff files)
    ["@diff.delta"] = { link = "diffChanged" }, -- deleted text (for diff files)

    -- Tags
    ["@tag"] = { fg = c.mauve },                         -- Tags like html tag names.
    ["@tag.attribute"] = { fg = c.teal, italic = true }, -- Tags like html tag names.
    ["@tag.delimiter"] = { fg = c.sky },                 -- Tag delimiter like < > /

    -- Misc
    ["@error"] = { link = "Error" },

    -- lua
    ["@constructor.lua"] = { fg = c.flamingo }, -- For constructor calls and definitions: = { } in Lua.

    -- C/CPP
    ["@property.cpp"] = { link = "@variable" },
    ["@type.builtin.c"] = { link = "StorageClass" },
    ["@type.builtin.cpp"] = { link = "StorageClass" },

    -- gitcommit
    ["@comment.warning.gitcommit"] = { fg = c.yellow },

    -- gitignore
    ["@string.special.path.gitignore"] = { fg = c.text },

    -- Misc
    gitcommitSummary = { fg = c.rosewater, italic = true },
    zshKSHFunction = { link = "Function" },
  }

  return colors
end

return M
