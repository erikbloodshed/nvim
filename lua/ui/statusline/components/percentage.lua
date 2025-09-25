-- ===================================================================
-- ui/statusline/components/percentage.lua
local api = vim.api

local modes_tbl = {
  n = { text = " NOR ", hl = "StatusLineNormal" },
  i = { text = " INS ", hl = "StatusLineInsert" },
  v = { text = " VIS ", hl = "StatusLineVisual" },
  V = { text = " V-L ", hl = "StatusLineVisual" },
  ["\22"] = { text = " V-B ", hl = "StatusLineVisual" },
  s = { text = " SEL ", hl = "StatusLineSelect" },
  S = { text = " S-L ", hl = "StatusLineSelect" },
  ["\19"] = { text = " S-B ", hl = "StatusLineSelect" },
  r = { text = " REP ", hl = "StatusLineReplace" },
  R = { text = " REP ", hl = "StatusLineReplace" },
  Rv = { text = " R-V ", hl = "StatusLineReplace" },
  c = { text = " CMD ", hl = "StatusLineCommand" },
  __index = function() return { text = " ??? ", hl = "StatusLineNormal" } end,
}
setmetatable(modes_tbl, modes_tbl)

local M = {
  enabled = true,
  priority = 0,
  cache_keys = {},
}

function M.render(ctx, apply_hl)
  local conditional_hl = require('ui.statusline').conditional_hl
  local mode_info = modes_tbl[api.nvim_get_mode().mode]
  return conditional_hl(" %P ", mode_info.hl, apply_hl)
end

return M

