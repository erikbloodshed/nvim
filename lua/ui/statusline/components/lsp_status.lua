return {
  cache_keys = { "lsp_clients" },
  events = { "BufWinEnter", "BufWritePost", "LspAttach", "LspDetach" },
  render = function(ctx, apply_hl)
    local clients = ctx.cache:get("lsp_clients", function()
      return vim.lsp.get_clients({ bufnr = ctx.bufnr })
    end)
    if not clients or vim.tbl_isempty(clients) then return "" end
    local names = {}
    for _, client in ipairs(clients) do
      names[#names + 1] = client.name
    end
    local content = ctx.icons.lsp .. " " .. table.concat(names, ", ")
    return ctx.hl_rule(content, "StatusLineLsp", apply_hl)
  end,
}
