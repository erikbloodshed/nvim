return {
  cache_keys = { "diagnostics" },
  events = { "DiagnosticChanged", "BufWinEnter", "BufWritePost" },
  render = function(ctx, apply_hl)
    local counts = ctx.cache:get("diagnostics", function()
      return vim.diagnostic.count(ctx.bufnr)
    end)
    if not counts or vim.tbl_isempty(counts) then
      return ctx.hl_rule(ctx.icons.ok, "DiagnosticOk", apply_hl)
    end
    local parts = {}
    local diag_tbl = ctx.config.diags_tbl
    for _, diag in ipairs(diag_tbl) do
      local count = counts[diag.severity_idx]
      if count and count > 0 then
        parts[#parts + 1] = ctx.hl_rule(
          string.format("%s:%d", diag.icon, count), diag.hl, apply_hl)
      end
    end
    return table.concat(parts, " ")
  end,
}
