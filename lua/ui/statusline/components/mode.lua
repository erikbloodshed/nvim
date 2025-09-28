return {
  events = {},
  render = function(ctx, apply_hl)
    return ctx.hl_rule(ctx.mode_info.text, ctx.mode_info.hl, apply_hl)
  end,
}
