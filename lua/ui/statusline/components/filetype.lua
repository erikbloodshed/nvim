return {
  events = { "BufWinEnter", "BufWritePost" },
  cache_keys = { "filetype" },
  render = function(ctx, apply_hl)
    local ft = ctx.filetype ~= "" and ctx.filetype or "none"
    return ctx.hl_rule(ft, "StatusLine", apply_hl)
  end,
}
