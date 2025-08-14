-- Ayu Mirage syntax highlighting
local M = {}

function M.get_highlights(palette)
  return {
    -- Basic syntax groups (using Ayu Mirage colors)
    Constant = { fg = palette.syntax.constant },                -- "#DFBFFF" - purple for constants
    Character = { fg = palette.syntax.string },                 -- "#D5FF80" - green for characters
    Comment = { fg = palette.syntax.comment, italic = true },   -- blended color for comments
    Debug = { fg = palette.syntax.special },                    -- "#FFDFB3" - light orange for debug
    Define = { fg = palette.syntax.keyword },                   -- "#FFAD66" - orange for defines
    Delimiter = { fg = palette.editor.fg },                     -- "#CCCAC2" - editor foreground
    Error = { fg = palette.common.error },                      -- "#FF6666" - red for errors
    Exception = { fg = palette.syntax.keyword },                -- "#FFAD66" - orange for exceptions
    Function = { fg = palette.syntax.func, bold = true },       -- "#FFD173" - yellow for functions
    Identifier = { fg = palette.editor.fg },                    -- "#CCCAC2" - editor foreground
    Ignore = { fg = palette.syntax.comment },                   -- comment color for ignored
    Include = { fg = palette.syntax.keyword },                  -- "#FFAD66" - orange for includes
    Macro = { fg = palette.syntax.special },                    -- "#FFDFB3" - light orange for macros
    Operator = { fg = palette.syntax.operator },                -- "#F29E74" - coral for operators
    PreCondit = { fg = palette.syntax.keyword },                -- "#FFAD66" - orange for preconditionals
    PreProc = { fg = palette.syntax.keyword },                  -- "#FFAD66" - orange for preprocessor
    Special = { fg = palette.syntax.special },                  -- "#FFDFB3" - light orange for special
    SpecialChar = { fg = palette.syntax.entity },               -- "#73D0FF" - blue for special chars
    SpecialComment = { fg = palette.syntax.tag },               -- "#5CCFE6" - cyan for special comments
    Statement = { fg = palette.syntax.keyword },                -- "#FFAD66" - orange for statements
    StorageClass = { fg = palette.syntax.keyword },             -- "#FFAD66" - orange for storage class
    String = { fg = palette.syntax.string },                    -- "#D5FF80" - green for strings
    Structure = { fg = palette.syntax.entity },                 -- "#73D0FF" - blue for structures
    Tag = { fg = palette.syntax.tag },                          -- "#5CCFE6" - cyan for tags
    Todo = { fg = palette.syntax.markup, bold = true },         -- "#F28779" - coral for todos
    Type = { fg = palette.syntax.entity },                      -- "#73D0FF" - blue for types
    Typedef = { fg = palette.syntax.entity },                   -- "#73D0FF" - blue for typedefs
    Underlined = { fg = palette.syntax.tag, underline = true }, -- "#5CCFE6" - cyan underlined
  }
end

return M
