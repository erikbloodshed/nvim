local g = vim.g
local o = vim.o
local api = vim.api
local darken = require("themes.decaffuccin.utils").darken

o.termguicolors = true
o.background = "dark"

if g.colors_name then
  vim.cmd.highlight("clear")
end

g.colors_name = "decaffuccin"


local opts = {
  transparency = false,
  float = {
    transparent = true,
    solid = true,
  },
  show_end_of_buffer = false,
  term_colors = false,
  dim_inactive = {
    enabled = true,
    shade = "dark",
    percentage = 0.15,
  },
  no_italic = false,
  no_bold = false,
  no_underline = false,
}

local c = {
  rosewater = "#f5e0dc",
  flamingo  = "#f2cdcd",
  pink      = "#f5c2e7",
  mauve     = "#cba6f7",
  red       = "#f38ba8",
  maroon    = "#eba0ac",
  peach     = "#fab387",
  yellow    = "#f9e2af",
  green     = "#a6e3a1",
  teal      = "#94e2d5",
  sky       = "#89dceb",
  sapphire  = "#74c7ec",
  blue      = "#89b4fa",
  lavender  = "#b4befe",
  text      = "#cdd6f4",
  subtext1  = "#bac2de",
  subtext0  = "#a6adc8",
  overlay2  = "#9399b2",
  overlay1  = "#7f849c",
  overlay0  = "#6c7086",
  surface2  = "#585b70",
  surface1  = "#45475a",
  surface0  = "#313244",
  base      = "#1e1e2e",
  mantle    = "#181825",
  crust     = "#11111b",
  none      = "NONE"
}

local function apply_highlights()
  c.dim = darken(c.base, opts.dim_inactive.percentage, c.mantle)
  c.bg_dvt_error = darken(c.red, 0.095, c.base)
  c.bg_dvt_warn = darken(c.yellow, 0.095, c.base)
  c.bg_dvt_info = darken(c.sky, 0.095, c.base)
  c.bg_dvt_hint = darken(c.teal, 0.095, c.base)
  c.bg_dvt_ok = darken(c.green, 0.095, c.base)
  c.bg_inlay_hint = darken(c.surface0, 0.64, c.base)
  c.bg_diff_add = darken(c.green, 0.18, c.base)
  c.bg_diff_change = darken(c.blue, 0.07, c.base)
  c.bg_diff_delete = darken(c.red, 0.18, c.base)
  c.bg_diff_text = darken(c.blue, 0.30, c.base)
  c.bg_cursorline = darken(c.surface0, 0.64, c.base)
  c.bg_pmenu = darken(c.surface0, 0.8, c.crust)
  c.bg_search = darken(c.sky, 0.30, c.base)
  c.bg_incsearch = darken(c.sky, 0.90, c.base)
  c.bg_blink_menu = darken(c.surface0, 0.8, c.crust)

  local modules = {
    require("themes.decaffuccin.schema.editor").get(c, opts),
    require("themes.decaffuccin.schema.native_lsp").get(c, opts),
    require("themes.decaffuccin.schema.syntax").get(c, opts),
    require("themes.decaffuccin.schema.treesitter").get(c),
    require("themes.decaffuccin.schema.semantic_tokens").get(c),
    require("themes.decaffuccin.schema.blink").get(c, opts),
    require("themes.decaffuccin.schema.neotree").get(c, opts)
  }

  local all_highlights = {}
  for _, mod in pairs(modules) do
    for name, attrs in pairs(mod) do
      all_highlights[name] = attrs
    end
  end

  local hl = api.nvim_set_hl
  for name, attrs in pairs(all_highlights) do
    hl(0, name, attrs)
  end
end

local ok, err = pcall(apply_highlights)
if not ok then
  vim.notify("Theme loading failed: " .. err, vim.log.levels.ERROR)
end

local term = require("themes.decaffuccin.schema.terminal").get(c)
for i, color in pairs(term) do
  vim.g[i] = color
end
