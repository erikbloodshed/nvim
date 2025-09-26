local config = require("ui.statusline.config")
local core = require("ui.statusline.core")

core.register_cmp("simple_title", function(ctx, apply_hl)
  local title = config.excluded.buftype[ctx.buftype] or config.excluded.filetype[ctx.filetype]
  return core.hl_rule(title or "no file", "String", apply_hl)
end)

