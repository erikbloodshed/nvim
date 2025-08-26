local g, o, api = vim.g, vim.o, vim.api

o.termguicolors = true
o.background = "dark"

if g.colors_name then
  vim.cmd.highlight("clear")
end

g.colors_name = "decaffuccin"

local cfg = {
  transparency = false,
  float = {
    transparent = false,
    solid = true,
  },
  show_end_of_buffer = false,
  dim_inactive = {
    enabled = false,
    percentage = 0.15,
  },
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
  none = "NONE"
}

local function apply_highlights()
  local pat = "^#([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])$"

  local rgb = function(hex_str)
    local red, green, blue = string.match(string.lower(hex_str), pat)
    return { tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16) }
  end

  local darken = function(f, a, b)
    b, f = rgb(b), rgb(f)
    local blendChannel = function(i)
      local ret = (a * f[i] + ((1 - a) * b[i]))
      return math.floor(math.min(math.max(0, ret), 255) + 0.5)
    end

    return string.format("#%02X%02X%02X", blendChannel(1), blendChannel(2), blendChannel(3))
  end

  c.dim = darken(c.base, cfg.dim_inactive.percentage, c.mantle)
  c.bg_dvt_error = darken(c.red, 0.095, c.base)
  c.bg_dvt_warn = darken(c.yellow, 0.095, c.base)
  c.bg_dvt_info = darken(c.sky, 0.095, c.base)
  c.bg_dvt_hint = darken(c.teal, 0.095, c.base)
  c.bg_dvt_ok = darken(c.green, 0.095, c.base)
  c.bg_inlay_hint = darken(c.surface0, 0.64, c.base)
  c.bg_line = darken(c.surface0, 0.64, c.base)
  c.bg_diff_add = darken(c.green, 0.18, c.base)
  c.bg_diff_change = darken(c.blue, 0.07, c.base)
  c.bg_diff_delete = darken(c.red, 0.18, c.base)
  c.bg_diff_text = darken(c.blue, 0.30, c.base)
  c.bg_search = darken(c.sky, 0.30, c.base)
  c.bg_incsearch = darken(c.sky, 0.90, c.base)

  local mod = {
    require("themes.decaffuccin.schema.editor").get(c, cfg),
    require("themes.decaffuccin.schema.native_lsp").get(c, cfg),
    require("themes.decaffuccin.schema.syntax").get(c, cfg),
    require("themes.decaffuccin.schema.treesitter").get(c),
    require("themes.decaffuccin.schema.semantic_tokens").get(c),
    require("themes.decaffuccin.schema.blink").get(c),
    require("themes.decaffuccin.schema.neotree").get(c, cfg)
  }

  local all_highlights = {}
  for _, m in pairs(mod) do
    for n, a in pairs(m) do all_highlights[n] = a end
  end

  local hl = api.nvim_set_hl
  for n, a in pairs(all_highlights) do hl(0, n, a) end
end

local ok, err = pcall(apply_highlights)
if not ok then
  vim.notify("Theme loading failed: " .. err, vim.log.levels.ERROR)
end

local term = require("themes.decaffuccin.schema.terminal").get(c)
for i, color in pairs(term) do
  vim.g[i] = color
end
