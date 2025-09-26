local icons = require("ui.icons")
local core = require("ui.statusline.core")
local cmp = require("ui.statusline.cmp")

cmp.register_cmp("file_status", function(ctx, apply_hl)
  local s = ctx.cache:get("file_status", function()
    return { readonly = ctx.readonly, modified = ctx.modified }
  end)
  return s.readonly and core.hl_rule(icons.readonly, "StatusLineReadonly", apply_hl)
      or s.modified and core.hl_rule(icons.modified, "StatusLineModified", apply_hl)
      or " "
end, { cache_keys = { "file_status" } })

