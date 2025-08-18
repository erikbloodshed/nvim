local c = require("themes.tokyonight-luna.colors")
local tc = c.terminal
local g = vim.g
local M = {}

M.init = function(bg_clear)
  require("themes.tokyonight-luna.schema.base").get(c, bg_clear)
  require("themes.tokyonight-luna.schema.treesitter").get(c)
  require("themes.tokyonight-luna.schema.semantic-token").get(c)
  require("themes.tokyonight-luna.schema.blink").get(c)
  require("themes.tokyonight-luna.schema.neotree").get(c)
  require("themes.tokyonight-luna.schema.render-markdown").get(c)

  g.terminal_color_0  = tc.black
  g.terminal_color_1  = tc.red
  g.terminal_color_2  = tc.green
  g.terminal_color_3  = tc.yellow
  g.terminal_color_4  = tc.blue
  g.terminal_color_5  = tc.magenta
  g.terminal_color_6  = tc.cyan
  g.terminal_color_7  = tc.white
  g.terminal_color_8  = tc.black_bright
  g.terminal_color_9  = tc.red_bright
  g.terminal_color_10 = tc.green_bright
  g.terminal_color_11 = tc.yellow_bright
  g.terminal_color_12 = tc.blue_bright
  g.terminal_color_13 = tc.magenta_bright
  g.terminal_color_14 = tc.cyan_bright
  g.terminal_color_15 = tc.white_bright
end

return M
