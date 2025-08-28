local M = {}

M = {
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

local p = "^#([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])$"

local rgb = function(h)
  local r, g, b = string.match(string.lower(h), p)
  return { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) }
end

local dkn = function(f, a, b)
  b, f = rgb(b), rgb(f)
  local blend = function(i)
    local r = (a * f[i] + ((1 - a) * b[i]))
    return math.floor(math.min(math.max(0, r), 255) + 0.5)
  end
  return string.format("#%02X%02X%02X", blend(1), blend(2), blend(3))
end

M.dim = dkn(M.base, 0.15, M.mantle)
M.bg_dvt_error = dkn(M.red, 0.095, M.base)
M.bg_dvt_warn = dkn(M.yellow, 0.095, M.base)
M.bg_dvt_info = dkn(M.sky, 0.095, M.base)
M.bg_dvt_hint = dkn(M.teal, 0.095, M.base)
M.bg_dvt_ok = dkn(M.green, 0.095, M.base)
M.bg_line = dkn(M.surface0, 0.64, M.base)
M.bg_diff_add = dkn(M.green, 0.18, M.base)
M.bg_diff_change = dkn(M.blue, 0.07, M.base)
M.bg_diff_delete = dkn(M.red, 0.18, M.base)
M.bg_diff_text = dkn(M.blue, 0.30, M.base)
M.bg_search = dkn(M.sky, 0.30, M.base)
M.bg_incsearch = dkn(M.sky, 0.90, M.base)

return M
