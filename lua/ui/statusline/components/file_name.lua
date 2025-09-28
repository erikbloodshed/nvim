local api, fn = vim.api, vim.fn

return {
  cache_keys = { "file_name" },
  render = function(ctx, apply_hl)
    local name = ctx.cache:get("file_name", function()
      local full = api.nvim_buf_get_name(ctx.bufnr)
      return (full == "") and "[No Name]" or fn.fnamemodify(full, ":t")
    end)

    return ctx.hl_rule(name, "StatusLine", apply_hl)
  end,
}
