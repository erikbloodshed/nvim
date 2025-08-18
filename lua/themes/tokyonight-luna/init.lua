local c = require("themes.tokyonight-luna.colors")
local g = vim.g

return function(bg_clear)
  require("themes.tokyonight-luna.schema.base").get(c, bg_clear)
  require("themes.tokyonight-luna.schema.treesitter").get(c)
  require("themes.tokyonight-luna.schema.semantic-token").get(c)
  require("themes.tokyonight-luna.schema.blink").get(c)
  require("themes.tokyonight-luna.schema.neotree").get(c)
  require("themes.tokyonight-luna.schema.render-markdown").get(c)

  g.terminal_color_0  = c.black
  g.terminal_color_1  = c.red
  g.terminal_color_2  = c.green
  g.terminal_color_3  = c.yellow
  g.terminal_color_4  = c.blue
  g.terminal_color_5  = c.magenta
  g.terminal_color_6  = c.cyan
  g.terminal_color_7  = c.white
  g.terminal_color_8  = c.black_bright
  g.terminal_color_9  = c.red_bright
  g.terminal_color_10 = c.green_bright
  g.terminal_color_11 = c.yellow_bright
  g.terminal_color_12 = c.blue_bright
  g.terminal_color_13 = c.magenta_bright
  g.terminal_color_14 = c.cyan_bright
  g.terminal_color_15 = c.white_bright
end
