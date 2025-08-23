local g = vim.g
local o = vim.o
local api = vim.api
local transparency = false

o.termguicolors = true
o.background = "dark"

if g.colors_name then
  vim.cmd.highlight("clear")
end

g.colors_name = "luna"

local function apply_highlights()
  local hl = api.nvim_set_hl
  local c = {
    bg             = "#222436",
    bg_dark        = "#1e2030",
    bg_dark2       = "#2f334d",
    bg_dark3       = "#444a73",
    bg_dark4       = "#24283c",
    bg_param       = "#262e4c",
    bg_add         = "#273849",
    bg_change      = "#252a3f",
    bg_delete      = "#3a273a",
    bg_error       = "#382c3d",
    bg_warn        = "#38343d",
    bg_info        = "#203346",
    bg_hint        = "#273644",
    bg_text        = "#394b70",
    bg_selection   = "#363c58",
    bg_sbar        = "#27293a",
    fg             = "#c8d3f5",
    fg_comment     = "#636da6",
    fg_dark        = "#828bb8",
    fg_gutter      = "#3b4261",
    fg_border      = "#28a3bc",
    fg_delimiter   = "#607cbd",
    black          = "#1b1d2b",
    dark           = "#181a26",
    blue           = "#7aa2f7",
    blue0          = "#3e68d7",
    blue1          = "#2ac3de",
    blue2          = "#0db9d7",
    blue5          = "#89ddff",
    blue6          = "#b4f9f8",
    blue7          = "#59c8e5",
    blue8          = "#2c3c6e",
    cyan           = "#86e1fc",
    dark5          = "#737aa2",
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
    br_black       = "#26283b",
    br_red         = "#ff828c",
    br_green       = "#d1f59b",
    br_yellow      = "#ffd38a",
    br_blue        = "#87b0ff",
    br_magenta     = "#d0a8ff",
    br_cyan        = "#94f0ff",
    br_white       = "#969fc8",
    none           = "NONE",
  }
  c.background = transparency and c.none or c.bg

  local modules = {
    require("themes.luna.schema.ui").get(c),
    require("themes.luna.schema.coding").get(c),
    require("themes.luna.schema.extensions").get(c),
  }

  local all_highlights = {}

  for _, mod in pairs(modules) do
    for name, attrs in pairs(mod) do
      all_highlights[name] = attrs
    end
  end

  for name, attrs in pairs(all_highlights) do
    hl(0, name, attrs)
  end
end

local ok, err = pcall(apply_highlights)
if not ok then
  vim.notify("Theme loading failed: " .. err, vim.log.levels.ERROR)
end
