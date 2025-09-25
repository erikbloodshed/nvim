-- ===================================================================
-- ui/statusline/components/position.lua
local M = {
  enabled = true,
  priority = 1,
  cache_keys = {},
}

function M.render(_, apply_hl)
  local conditional_hl = require('ui.statusline').conditional_hl
  return conditional_hl("%l:%v", "StatusLineValue", apply_hl)
end

return M
