local M = {}

function M.get(c)
  local highlights = {
    BlinkCmpMenuBorder = { fg = c.surface2, bg = c.mantle },
    linkCmpDocBorder = { link = "FloatBorder" },
    BlinkCmpLabel = { fg = c.overlay2 },
    BlinkCmpLabelDeprecated = { fg = c.overlay0, strikethrough = true },
    BlinkCmpKind = { fg = c.blue },
    BlinkCmpMenu = { link = "Pmenu" },
    BlinkCmpDoc = { link = "NormalFloat" },
    BlinkCmpLabelMatch = { fg = c.text, bold = true },
    BlinkCmpMenuSelection = { bg = c.surface1, bold = true },
    BlinkCmpScrollBarGutter = { bg = c.surface1 },
    BlinkCmpScrollBarThumb = { bg = c.overlay0 },
    BlinkCmpLabelDescription = { fg = c.overlay0 },
    BlinkCmpLabelDetail = { fg = c.overlay0 },

    BlinkCmpKindText = { fg = c.green },
    BlinkCmpKindMethod = { fg = c.blue },
    BlinkCmpKindFunction = { fg = c.blue },
    BlinkCmpKindConstructor = { fg = c.blue },
    BlinkCmpKindField = { fg = c.green },
    BlinkCmpKindVariable = { fg = c.flamingo },
    BlinkCmpKindClass = { fg = c.yellow },
    BlinkCmpKindInterface = { fg = c.yellow },
    BlinkCmpKindModule = { fg = c.blue },
    BlinkCmpKindProperty = { fg = c.blue },
    BlinkCmpKindUnit = { fg = c.green },
    BlinkCmpKindValue = { fg = c.peach },
    BlinkCmpKindEnum = { fg = c.yellow },
    BlinkCmpKindKeyword = { fg = c.mauve },
    BlinkCmpKindSnippet = { fg = c.flamingo },
    BlinkCmpKindColor = { fg = c.red },
    BlinkCmpKindFile = { fg = c.blue },
    BlinkCmpKindReference = { fg = c.red },
    BlinkCmpKindFolder = { fg = c.blue },
    BlinkCmpKindEnumMember = { fg = c.teal },
    BlinkCmpKindConstant = { fg = c.peach },
    BlinkCmpKindStruct = { fg = c.blue },
    BlinkCmpKindEvent = { fg = c.blue },
    BlinkCmpKindOperator = { fg = c.sky },
    BlinkCmpKindTypeParameter = { fg = c.maroon },
    BlinkCmpKindCopilot = { fg = c.teal },
  }

  return highlights
end

return M
