local core = require("ui.statusline.core")
local cmp = require("ui.statusline.cmp")

cmp.register_cmp("percentage", function(ctx, apply_hl)
  return core.hl_rule(" %P ", ctx.mode_info.hl, apply_hl)
end)

