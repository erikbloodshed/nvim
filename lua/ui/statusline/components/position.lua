local core = require("ui.statusline.core")
local cmp = require("ui.statusline.cmp")

cmp.register_cmp("position", function(_, apply_hl)
  return core.hl_rule("%l:%v", "StatusLineValue", apply_hl)
end)

