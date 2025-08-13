-- Traditional syntax highlighting for Nord theme
local M = {}

function M.get_highlights(palette)
  return {
    -- Basic syntax groups (following Nord spec)
    Constant = { fg = palette.orange.base },
    Character = { fg = palette.green.base },
    Comment = { fg = palette.gray5, italic = true }, -- Used for WCAG compliance (5.75:1)
    Debug = { fg = palette.yellow.base },
    Define = { fg = palette.blue1 },
    Delimiter = { fg = palette.white0_normal },
    Error = { fg = palette.red.bright },
    Exception = { fg = palette.blue1 },
    Function = { fg = palette.blue0.base },
    Identifier = { fg = palette.white0_normal },
    Ignore = { fg = palette.gray5 },
    Include = { fg = palette.blue1 },
    Macro = { fg = palette.blue2 },
    Operator = { fg = palette.white0_normal },
    PreCondit = { fg = palette.blue1 },
    PreProc = { fg = palette.blue1 }, -- Changed for better contrast (6.1:1)
    Special = { fg = palette.blue2 },
    SpecialChar = { fg = palette.blue1 },
    SpecialComment = { fg = palette.cyan.base },
    Statement = { fg = palette.magenta.base },
    StorageClass = { fg = palette.blue1 },
    String = { fg = palette.green.base },
    Structure = { fg = palette.cyan.base },
    Tag = { fg = palette.blue1 },
    Todo = { fg = palette.cyan.base, bold = true },
    Type = { fg = palette.cyan.base },
    Typedef = { fg = palette.cyan.base },
    Underlined = { fg = palette.cyan.base, underline = true },
  }
end

return M
