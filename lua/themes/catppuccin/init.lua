local g = vim.g
local o = vim.o
local api = vim.api
local transparency = false

o.termguicolors = true
o.background = "dark"

if g.colors_name then
  vim.cmd.highlight("clear")
end

g.colors_name = "catppuccin"

local function apply_highlights()
  local hl = api.nvim_set_hl
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
    overlay0  = "#6c7086",
    surface2  = "#585b70",
    surface1  = "#45475a",
    surface0  = "#313244",
    base      = "#1e1e2e",
    mantle    = "#181825",
    crust     = "#11111b",
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
