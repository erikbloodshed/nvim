local blend        = require("themes.util").blend
local blend_bg     = require("themes.util").blend_bg
local brighten     = require("themes.util").brighten

local M            = {
  bg             = "#222436",
  bg_dark        = "#1e2030",
  bg_dark2       = "#2f334d",
  bg_dark3       = "#444a73",
  blue           = "#82aaff",
  blue0          = "#3e68d7",
  blue1          = "#65bcff",
  blue2          = "#0db9d7",
  blue5          = "#89ddff",
  blue6          = "#b4f9f8",
  blue7          = "#394b70",
  comment        = "#636da6",
  cyan           = "#86e1fc",
  dark5          = "#737aa2",
  fg             = "#c8d3f5",
  fg_dark        = "#828bb8",
  fg_gutter      = "#3b4261",
  green          = "#c3e88d",
  green1         = "#41a6b5",
  magenta        = "#c099ff",
  orange         = "#ff966c",
  purple         = "#fca7ea",
  red            = "#ff757f",
  red1           = "#c53b53",
  teal           = "#4fd6be",
  terminal_black = "#444a73",
  yellow         = "#ffc777",
  none           = "NONE",
}

M.dark             = blend(M.bg_dark, 0.8, "#000000")
M.bg_visual        = blend_bg(M.blue0, 0.4, M.bg)
M.black            = blend_bg(M.bg, 0.8, "#000000")
M.border_highlight = blend_bg(M.blue1, 0.8, M.bg)

---@format disable-next
M.terminal = {
  black          = M.black,
  black_bright   = M.terminal_black,
  red            = M.red,
  red_bright     = brighten(M.red),
  green          = M.green,
  green_bright   = brighten(M.green),
  yellow         = M.yellow,
  yellow_bright  = brighten(M.yellow),
  blue           = M.blue,
  blue_bright    = brighten(M.blue),
  magenta        = M.magenta,
  magenta_bright = brighten(M.magenta),
  cyan           = M.cyan,
  cyan_bright    = brighten(M.cyan),
  white          = M.fg_dark,
  white_bright   = M.fg,
}

---@format disable-next
M.rainbow = { M.blue, M.yellow, M.green, M.teal, M.magenta, M.purple, M.orange, M.red, }

return M
