return {
  cache_keys = { "file_status" },
  events = { "BufWinEnter", "BufWritePost", "BufModifiedSet" },
  render = function(ctx, apply_hl)
    local s = ctx.cache:get("file_status", function()
      return { readonly = ctx.readonly, modified = ctx.modified }
    end)
    return s.readonly and ctx.hl_rule(ctx.icons.readonly, "StatusLineReadonly", apply_hl)
      or s.modified and ctx.hl_rule(ctx.icons.modified, "StatusLineModified", apply_hl)
      or " "
  end,
}
