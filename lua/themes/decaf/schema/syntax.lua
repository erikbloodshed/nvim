local M = {}

function M.get(c, o)
  return {
    Comment            = { fg = c.overlay2, italic = true },             -- just comments
    SpecialComment     = { link = "Special" },                           -- special things inside a comment
    Constant           = { fg = c.peach },                               -- (preferred) any constant
    String             = { fg = c.green },                               -- a string constant: "this is a string"
    Character          = { fg = c.teal },                                --  a character constant: 'c', '\n'
    Number             = { link = "Constant" },                          --   a number constant: 234, 0xff
    Float              = { link = "Constant" },                          --    a floating point constant: 2.3e10
    Boolean            = { link = "Constant" },                          --  a boolean constant: TRUE, false
    Identifier         = { fg = c.flamingo },                            -- (preferred) any variable name
    Function           = { fg = c.blue, bold = true, nocombine = true }, -- function name (also: methods for classes)
    Statement          = { fg = c.mauve },                               -- (preferred) any statement
    Conditional        = { link = "Statement" },                         --  if, then, else, endif, switch, etc.
    Repeat             = { link = "Statement" },                         --   for, do, while, etc.
    Label              = { fg = c.sapphire },                            --    case, default, etc.
    Operator           = { fg = c.sky },                                 -- "sizeof", "+", "*", etc.
    Keyword            = { link = "Statement" },                         --  any other keyword
    Exception          = { link = "Statement" },                         --  try, catch, throw

    PreProc            = { fg = c.pink },                                -- (preferred) generic Preprocessor
    Include            = { link = "Statement" },                         --  preprocessor #include
    Define             = { link = "PreProc" },                           -- preprocessor #define
    Macro              = { link = "Statement" },                         -- same as Define
    PreCondit          = { link = "PreProc" },                           -- preprocessor #if, #else, #endif, etc.

    StorageClass       = { fg = c.yellow, nocombine = true },            -- static, register, volatile, etc.
    Structure          = { link = "StorageClass" },                      --  struct, union, enum, etc.
    Special            = { fg = c.pink },                                -- (preferred) any special symbol
    Type               = { link = "StorageClass" },                      -- (preferred) int, long, char, etc.
    Typedef            = { link = "Type" },                              --  A typedef
    SpecialChar        = { link = "Special" },                           -- special character in a constant
    Tag                = { fg = c.lavender },                            -- you can use CTRL-] on this
    Delimiter          = { fg = c.overlay2 },                            -- character that needs attention
    Debug              = { link = "Special" },                           -- debugging statements

    Underlined         = { underline = true },                           -- (preferred) text that stands out, HTML links
    Bold               = { bold = true },
    Italic             = { italic = true },
    -- ("Ignore", below, may be invisible...)
    -- Ignore = { }, -- (preferred) left blank, hidden  |hl-Ignore|
    Error              = { fg = c.red },                                -- (preferred) any erroneous construct
    Todo               = { bg = c.flamingo, fg = c.base, bold = true }, -- (preferred) anything that needs extra attention; mostly the keywords TODO FIXME and XXX
    qfLineNr           = { fg = c.yellow },
    qfFileName         = { fg = c.blue },
    htmlH1             = { fg = c.pink, bold = true },
    htmlH2             = { fg = c.blue, bold = true },
    -- mkdHeading = { fg = c.peach, bold = true },
    -- mkdCode = { bg = c.terminal_black, fg = c.text },
    mkdCodeDelimiter   = { bg = c.base, fg = c.text },
    mkdCodeStart       = { fg = c.flamingo, bold = true },
    mkdCodeEnd         = { fg = c.flamingo, bold = true },
    -- mkdLink = { fg = C.blue, underline = true },

    -- debugging
    debugPC            = { bg = o.transparency and c.none or c.crust },
    debugBreakpoint    = { bg = c.base, fg = c.overlay0 },
    -- illuminate
    illuminatedWord    = { bg = c.surface1 },
    illuminatedCurWord = { bg = c.surface1 },
    -- diff
    diffAdded          = { fg = c.green },
    diffRemoved        = { fg = c.red },
    diffChanged        = { fg = c.blue },
    diffOldFile        = { fg = c.yellow },
    diffNewFile        = { fg = c.peach },
    diffFile           = { fg = c.blue },
    diffLine           = { fg = c.overlay0 },
    diffIndexLine      = { fg = c.teal },
    DiffAdd            = { bg = c.bg_diff_add },
    DiffChange         = { bg = c.bg_diff_change },
    DiffDelete         = { bg = c.bg_diff_delete },
    DiffText           = { bg = c.bg_diff_text },
    -- NeoVim
    healthError        = { link = "Error" },
    healthSuccess      = { fg = c.teal },
    healthWarning      = { fg = c.yellow },
    -- glyphs
    GlyphPalette1      = { fg = c.red },
    GlyphPalette2      = { fg = c.teal },
    GlyphPalette3      = { fg = c.yellow },
    GlyphPalette4      = { fg = c.blue },
    GlyphPalette6      = { fg = c.teal },
    GlyphPalette7      = { fg = c.text },
    GlyphPalette9      = { fg = c.red },
    -- rainbow
    rainbow1           = { fg = c.red },
    rainbow2           = { fg = c.peach },
    rainbow3           = { fg = c.yellow },
    rainbow4           = { fg = c.green },
    rainbow5           = { fg = c.sapphire },
    rainbow6           = { fg = c.lavender },
    -- csv
    csvCol0            = { fg = c.red },
    csvCol1            = { fg = c.peach },
    csvCol2            = { fg = c.yellow },
    csvCol3            = { fg = c.green },
    csvCol4            = { fg = c.sky },
    csvCol5            = { fg = c.blue },
    csvCol6            = { fg = c.lavender },
    csvCol7            = { fg = c.mauve },
    csvCol8            = { fg = c.pink },
  }
end

return M
