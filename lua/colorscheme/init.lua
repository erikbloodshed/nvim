local g = vim.g
local o = vim.o
local api = vim.api
local c = require("colorscheme.colors")

o.termguicolors = true
o.background = "dark"
vim.cmd.highlight("clear")

g.colors_name = "luna"

g.terminal_color_0 = c.black
g.terminal_color_1 = c.red
g.terminal_color_2 = c.green
g.terminal_color_3 = c.yellow
g.terminal_color_4 = c.blue
g.terminal_color_5 = c.magenta
g.terminal_color_6 = c.cyan
g.terminal_color_7 = c.fg_dark
g.terminal_color_8 = c.br_black
g.terminal_color_9 = c.br_red
g.terminal_color_10 = c.br_green
g.terminal_color_11 = c.br_yellow
g.terminal_color_12 = c.br_blue
g.terminal_color_13 = c.br_magenta
g.terminal_color_14 = c.br_cyan
g.terminal_color_15 = c.br_white

local function apply_highlights()
  local hl = api.nvim_set_hl

  local modules = {
    require("colorscheme.schema.ui").get(c),
    require("colorscheme.schema.coding").get(c),
    require("colorscheme.schema.extensions").get(c),
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

local ok, err = pcall(apply_highlights, c)
if not ok then
  vim.notify("Theme loading failed: " .. err, vim.log.levels.ERROR)
end
