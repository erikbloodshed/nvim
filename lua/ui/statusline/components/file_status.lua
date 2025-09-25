local icons = require("ui.icons")

local M = {
  enabled = true,
  priority = 7,
  cache_keys = { "file_status" },
}

function M.render(ctx, apply_hl)
  local conditional_hl = require('ui.statusline').conditional_hl

  local status = ctx.cache:get("file_status", function()
    return { readonly = ctx.bo.readonly, modified = ctx.bo.modified }
  end)

  if status.readonly then
    return conditional_hl(icons.readonly, "StatusLineReadonly", apply_hl)
  elseif status.modified then
    return conditional_hl(icons.modified, "StatusLineModified", apply_hl)
  end
  return " "
end

return M
