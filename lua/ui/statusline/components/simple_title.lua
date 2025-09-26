local excluded = require("ui.statusline.config").excluded
local core = require("ui.statusline.core")

return {
  render = function(ctx, apply_hl)
    local title = excluded.buftype[ctx.buftype] or excluded.filetype[ctx.filetype]
    return core.hl_rule(title or "no file", "String", apply_hl)
  end
}
