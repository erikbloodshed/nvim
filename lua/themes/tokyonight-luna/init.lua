local c        = require("themes.tokyonight-luna.colors")
local g        = vim.g
local blend    = require("themes.util").blend
local brighten = require("themes.util").brighten

return function(bg_clear)
  c.dark             = blend(c.bg_dark, 0.8, "#000000") -- #181926
  c.bg_visual        = blend(c.blue0, 0.35, c.bg)    -- #2b3b6e
  c.border_highlight = blend(c.blue1, 0.8, c.bg)     -- #579dd6
  c.black             = blend(c.bg, 0.8, "#000000")

  require("themes.tokyonight-luna.schema.base").get(c, bg_clear)
  require("themes.tokyonight-luna.schema.treesitter").get(c)
  require("themes.tokyonight-luna.schema.semantic-token").get(c)
  require("themes.tokyonight-luna.schema.status").get(c)
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
  g.terminal_color_7  = c.fg_dark
  g.terminal_color_8  = brighten(c.black)
  g.terminal_color_9  = brighten(c.red)
  g.terminal_color_10 = brighten(c.green)
  g.terminal_color_11 = brighten(c.yellow)
  g.terminal_color_12 = brighten(c.blue)
  g.terminal_color_13 = brighten(c.magenta)
  g.terminal_color_14 = brighten(c.cyan)
  g.terminal_color_15 = brighten(c.fg_dark)
end
