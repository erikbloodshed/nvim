return {
  render = function(ctx, apply_hl)
    local excluded = ctx.config.excluded
    local title = excluded.buftype[ctx.buftype] or excluded.filetype[ctx.filetype]
    return ctx.hl_rule(title or "no file", "String", apply_hl)
  end
}
