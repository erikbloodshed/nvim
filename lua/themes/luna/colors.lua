-- Tokyonight Moon Palette
local blend = require("themes.util").blend
local brighten = require("themes.util").brighten
local transparency = false

local M = {}

local base = {
  bg = "#222436",
  bg_dark = "#1e2030",
  bg_dark2 = "#2f334d",
  bg_dark3 = "#444a73",
  blue = "#7aa2f7",
  blue0 = "#3e68d7",
  blue1 = "#2ac3de",
  blue2 = "#0db9d7",
  blue5 = "#89ddff",
  blue6 = "#b4f9f8",
  blue7 = "#394b70",
  cyan = "#86e1fc",
  dark5 = "#737aa2",
  fg = "#c8d3f5",
  fg_dark = "#828bb8",
  green = "#c3e88d",
  green1 = "#41a6b5",
  magenta = "#c099ff",
  orange = "#ff966c",
  purple = "#fca7ea",
  red = "#ff757f",
  red1 = "#c53b53",
  teal = "#4fd6be",
  terminal_black = "#444a73",
  yellow = "#ffc777",
  comment = "#636da6",
  fg_gutter = "#3b4261",
  none = "NONE",
}

local calc = {
    dark = blend(base.bg_dark, 0.8, "#000000"),
    bg_visual = blend(base.blue0, 0.35, base.bg),
    border_highlight = blend(base.blue1, 0.8, base.bg),
    black = blend(base.bg, 0.8, "#000000"),
    param = brighten(base.red, 0.05),
    interface = blend(base.blue1, 0.7, base.fg),
    br_black = brighten(blend(base.bg, 0.8, "#000000")),
    br_red = brighten(base.red),
    br_green = brighten(base.green),
    br_yellow = brighten(base.yellow),
    br_blue = brighten(base.blue),
    br_magenta = brighten(base.magenta),
    br_cyan = brighten(base.cyan),
    br_white = brighten(base.fg_dark),
    type_var = blend(base.blue1, 0.7, base.fg),
    diff_add = blend(base.green1, 0.15, base.bg),
    diff_change = blend(base.blue7, 0.15, base.bg),
    diff_delete = blend(base.red1, 0.15, base.bg),
    error_bg = blend(base.red, 0.1, base.bg),
    warn_bg = blend(base.yellow, 0.1, base.bg),
    info_bg = blend(base.blue2, 0.1, base.bg),
    hint_bg = blend(base.teal, 0.1, base.bg),
    menu_sel = blend(base.fg_gutter, 0.8, base.bg),
    match_sel = blend(base.fg_gutter, 0.8, base.bg),
    s_bar = blend(base.bg_dark, 0.95, base.fg),
    lsp_signature_active_param = blend(blend(base.blue0, 0.35, base.bg), 0.4, base.bg),
    lsp_inlay_hint = blend(base.blue7, 0.1, base.bg),
    delimiter_tsx = blend(base.blue, 0.7, base.bg),
    background = transparency and base.none or base.bg
}

M = vim.tbl_extend("force", base, calc)

return M
