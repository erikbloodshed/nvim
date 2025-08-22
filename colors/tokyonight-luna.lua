local g = vim.g
local api = vim.api
local c = require("colorscheme.colors")
local hl = api.nvim_set_hl

vim.cmd.highlight("clear")
vim.cmd.syntax("reset")

vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "tokyonight-luna"
vim.g.matchparen_disable_cursor_hl = 1

local function apply_highlights()
  local modules = {
    require("colorscheme.schema.base"),
    require("colorscheme.schema.treesitter"),
    require("colorscheme.schema.semantic-token"),
    require("colorscheme.schema.status"),
    require("colorscheme.schema.blink"),
    require("colorscheme.schema.neotree"),
  }

  local all_highlights = {}

  for _, mod in ipairs(modules) do
    local highlights = mod.get(c)
    for name, attrs in pairs(highlights) do
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
