local core = require("ui.statusline.core")

core.register_cmp("mode", function(ctx, apply_hl)
  return core.hl_rule(ctx.mode_info.text, ctx.mode_info.hl, apply_hl)
end)

