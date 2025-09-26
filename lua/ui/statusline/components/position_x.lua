local core = require("ui.statusline.core")

core.register_cmp("position", function(_, apply_hl)
  return core.hl_rule("%l:%v", "StatusLineValue", apply_hl)
end)

