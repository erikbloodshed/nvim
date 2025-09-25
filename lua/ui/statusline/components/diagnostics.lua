local icons = require("ui.icons")

local diagnostics_tbl = {
  { icon = icons.error, hl = "DiagnosticError", severity_idx = 1 },
  { icon = icons.warn, hl = "DiagnosticWarn", severity_idx = 2 },
  { icon = icons.info, hl = "DiagnosticInfo", severity_idx = 3 },
  { icon = icons.hint, hl = "DiagnosticHint", severity_idx = 4 },
}

local M = {
  enabled = true,
  priority = 4,
  cache_keys = { "diagnostics" },
}

function M.render(ctx, apply_hl)
  local conditional_hl = require('ui.statusline').conditional_hl

  local counts = ctx.cache:get("diagnostics", function()
    return vim.diagnostic.count(ctx.bufnr)
  end)

  if not counts or vim.tbl_isempty(counts) then
    return conditional_hl(icons.ok, "DiagnosticOk", apply_hl)
  end

  local parts = {}
  for _, diag in ipairs(diagnostics_tbl) do
    local count = counts[diag.severity_idx]
    if count and count > 0 then
      parts[#parts + 1] = conditional_hl(string.format("%s:%d", diag.icon, count), diag.hl, apply_hl)
    end
  end
  return table.concat(parts, " ")
end

return M
