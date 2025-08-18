local colors = require("themes.tokyonight-luna.colors")
local M = {}

M.init = function(bg_clear)
  require("themes.tokyonight-luna.schema.base").get(colors, bg_clear)
  require("themes.tokyonight-luna.schema.treesitter").get(colors)
  require("themes.tokyonight-luna.schema.semantic-token").get(colors)
  require("themes.tokyonight-luna.schema.blink").get(colors)
  require("themes.tokyonight-luna.schema.neotree").get(colors)
  require("themes.tokyonight-luna.schema.render-markdown").get(colors)
end

return M
