return {
  render = function(ctx, apply_hl)
    return ctx.hl_rule(" %P ", ctx.mode_info.hl, apply_hl)
  end
}
