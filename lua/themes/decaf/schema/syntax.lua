local M = {}

function M.get(c)
  return {
    Comment            = { fg = c.overlay2, italic = true },
    SpecialComment     = { link = "Special" },
    Constant           = { fg = c.peach, nocombine = true },
    String             = { fg = c.green },
    Character          = { fg = c.teal },
    Number             = { link = "Constant" },
    Float              = { link = "Constant" },
    Boolean            = { link = "Constant" },
    Identifier         = { fg = c.flamingo },
    Function           = { fg = c.blue, bold = true, nocombine = true },
    Statement          = { fg = c.mauve },
    Conditional        = { link = "Statement" },
    Repeat             = { link = "Statement" },
    Label              = { fg = c.sapphire },
    Operator           = { fg = c.sky },
    Keyword            = { link = "Statement" },
    Exception          = { link = "Statement" },

    PreProc            = { fg = c.pink },
    Include            = { link = "Statement" },
    Define             = { link = "PreProc" },
    Macro              = { link = "Statement" },
    PreCondit          = { link = "PreProc" },

    StorageClass       = { fg = c.yellow, nocombine = true },
    Structure          = { link = "StorageClass" },
    Special            = { fg = c.pink },
    Type               = { link = "StorageClass" },
    Typedef            = { link = "Type" },
    SpecialChar        = { link = "Special" },
    Tag                = { fg = c.lavender },
    Delimiter          = { fg = c.overlay2 },
    Debug              = { link = "Special" },

    Underlined         = { underline = true },
    Bold               = { bold = true },
    Italic             = { italic = true },

    Error              = { fg = c.red },
    Todo               = { bg = c.flamingo, fg = c.base, bold = true },
    DiffAdd            = { bg = c.bg_diff_add },
    DiffChange         = { bg = c.bg_diff_change },
    DiffDelete         = { bg = c.bg_diff_delete },
    DiffText           = { bg = c.bg_diff_text },
  }
end

return M
