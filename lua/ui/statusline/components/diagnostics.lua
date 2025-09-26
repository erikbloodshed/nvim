local icons = require("ui.icons")
local diags_tbl = require("ui.statusline.config").diags_tbl
local core = require("ui.statusline.core")

return {
  cache_keys = { "diagnostics" },
  render = function(ctx, apply_hl)
    local counts = ctx.cache:get("diagnostics", function()
      return vim.diagnostic.count(ctx.bufnr)
    end)
    if not counts or vim.tbl_isempty(counts) then
      return core.hl_rule(icons.ok, "DiagnosticOk", apply_hl)
    end
    local parts = {}
    for _, diag in ipairs(diags_tbl) do
      local count = counts[diag.severity_idx]
      if count and count > 0 then
        parts[#parts + 1] = core.hl_rule(
          string.format("%s:%d", diag.icon, count), diag.hl, apply_hl)
      end
    end
    return table.concat(parts, " ")
  end,
}
