local core = require("ui.statusline.core")

core.register_cmp("percentage", function(ctx, apply_hl)
  return core.hl_rule(" %P ", ctx.mode_info.hl, apply_hl)
end)

