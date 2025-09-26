local icons = require("ui.icons")
local core = require("ui.statusline.core")

core.register_cmp("lsp_status", function(ctx, apply_hl)
  local clients = ctx.cache:get("lsp_clients", function()
    return vim.lsp.get_clients({ bufnr = ctx.bufnr })
  end)
  if not clients or vim.tbl_isempty(clients) then return "" end
  local names = {}
  for _, client in ipairs(clients) do
    names[#names + 1] = client.name
  end
  local content = icons.lsp .. " " .. table.concat(names, ", ")
  return core.hl_rule(content, "StatusLineLsp", apply_hl)
end, { cache_keys = { "lsp_clients" } })

