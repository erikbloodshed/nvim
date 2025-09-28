return {
  render = function(ctx, apply_hl)
    return ctx.hl_rule("%l:%v", "StatusLineValue", apply_hl)
  end
}
