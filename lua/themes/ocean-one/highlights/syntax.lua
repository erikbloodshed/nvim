local M = {}

function M.get_highlights(p)
  return {
    -- Basic syntax groups (using Ayu Mirage colors)
    Constant = { fg = p.syntax.constant },                -- "#DFBFFF" - purple for constants
    Character = { fg = p.syntax.string },                 -- "#D5FF80" - green for characters
    Comment = { fg = p.syntax.comment, italic = true },   -- blended color for comments
    Debug = { fg = p.syntax.special },                    -- "#FFDFB3" - light orange for debug
    Define = { fg = p.syntax.keyword },                   -- "#FFAD66" - orange for defines
    Delimiter = { fg = p.editor.fg },                     -- "#CCCAC2" - editor foreground
    Error = { fg = p.common.error },                      -- "#FF6666" - red for errors
    Exception = { fg = p.syntax.keyword },                -- "#FFAD66" - orange for exceptions
    Function = { fg = p.syntax.func, bold = true },       -- "#FFD173" - yellow for functions
    Identifier = { fg = p.editor.fg },                    -- "#CCCAC2" - editor foreground
    Ignore = { fg = p.syntax.comment },                   -- comment color for ignored
    Include = { fg = p.syntax.keyword },                  -- "#FFAD66" - orange for includes
    Macro = { fg = p.syntax.special },                    -- "#FFDFB3" - light orange for macros
    Operator = { fg = p.syntax.operator },                -- "#F29E74" - coral for operators
    PreCondit = { fg = p.syntax.keyword },                -- "#FFAD66" - orange for preconditionals
    PreProc = { fg = p.syntax.keyword },                  -- "#FFAD66" - orange for preprocessor
    Special = { fg = p.syntax.special },                  -- "#FFDFB3" - light orange for special
    SpecialChar = { fg = p.syntax.entity },               -- "#73D0FF" - blue for special chars
    SpecialComment = { fg = p.syntax.tag },               -- "#5CCFE6" - cyan for special comments
    Statement = { fg = p.syntax.keyword },                -- "#FFAD66" - orange for statements
    StorageClass = { fg = p.syntax.keyword },             -- "#FFAD66" - orange for storage class
    String = { fg = p.syntax.string },                    -- "#D5FF80" - green for strings
    Structure = { fg = p.syntax.entity },                 -- "#73D0FF" - blue for structures
    Tag = { fg = p.syntax.tag },                          -- "#5CCFE6" - cyan for tags
    Todo = { fg = p.syntax.markup, bold = true },         -- "#F28779" - coral for todos
    Type = { fg = p.syntax.entity },                      -- "#73D0FF" - blue for types
    Typedef = { fg = p.syntax.entity },                   -- "#73D0FF" - blue for typedefs
    Underlined = { fg = p.syntax.tag, underline = true }, -- "#5CCFE6" - cyan underlined
  }
end

return M
