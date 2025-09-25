local icons = require("ui.icons")

local M = {
  enabled = true,
  priority = 2,
  cache_keys = { "lsp_clients" },
}

function M.render(ctx, apply_hl)
  local conditional_hl = require('ui.statusline').conditional_hl

  local clients = ctx.cache:get("lsp_clients", function()
    return vim.lsp.get_clients({ bufnr = ctx.bufnr })
  end)

  if not clients or vim.tbl_isempty(clients) then return "" end

  local names = {}
  for _, client in ipairs(clients) do
    names[#names + 1] = client.name
  end

  local content = icons.lsp .. " " .. table.concat(names, ", ")
  return conditional_hl(content, "StatusLineLsp", apply_hl)
end

return M
