local core = require("ui.statusline.core")

return {
  cache_keys = { "file_status" },
  render = function(ctx, apply_hl)
    local s = ctx.cache:get("file_status", function()
      return { readonly = ctx.readonly, modified = ctx.modified }
    end)
    return s.readonly and core.hl_rule(ctx.readonly, "StatusLineReadonly", apply_hl)
      or s.modified and core.hl_rule(ctx.modified, "StatusLineModified", apply_hl)
      or " "
  end,
}
