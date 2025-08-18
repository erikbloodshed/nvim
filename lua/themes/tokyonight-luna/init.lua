local colors = require("themes.tokyonight-luna.colors")
local term_colors = colors.terminal
local g = vim.g
local M = {}

M.init = function(bg_clear)
  require("themes.tokyonight-luna.schema.base").get(colors, bg_clear)
  require("themes.tokyonight-luna.schema.treesitter").get(colors)
  require("themes.tokyonight-luna.schema.semantic-token").get(colors)
  require("themes.tokyonight-luna.schema.blink").get(colors)
  require("themes.tokyonight-luna.schema.neotree").get(colors)
  require("themes.tokyonight-luna.schema.render-markdown").get(colors)

  g.terminal_color_0  = term_colors.black
  g.terminal_color_1  = term_colors.black_bright
  g.terminal_color_2  = term_colors.red
  g.terminal_color_3  = term_colors.red_bright
  g.terminal_color_4  = term_colors.green
  g.terminal_color_5  = term_colors.green_bright
  g.terminal_color_6  = term_colors.yellow
  g.terminal_color_7  = term_colors.yellow_bright
  g.terminal_color_8  = term_colors.blue
  g.terminal_color_9  = term_colors.blue_bright
  g.terminal_color_10 = term_colors.magenta
  g.terminal_color_11 = term_colors.magenta_bright
  g.terminal_color_12 = term_colors.cyan
  g.terminal_color_13 = term_colors.cyan_bright
  g.terminal_color_14 = term_colors.white
  g.terminal_color_15 = term_colors.white_bright
end

return M
