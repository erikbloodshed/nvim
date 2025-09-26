local api, fn = vim.api, vim.fn
local icons = require("ui.icons")
local core = require("ui.statusline.core")

core.register_cmp("directory", function(ctx, apply_hl)
  local path = ctx.cache:get("directory", function()
    local buf_name = api.nvim_buf_get_name(ctx.bufnr)
    return (buf_name == "") and fn.getcwd() or fn.fnamemodify(buf_name, ":p:h")
  end)
  if not path or path == "" then return "" end
  local display_name = fn.fnamemodify(path, ":~")
  local content = icons.folder .. " " .. display_name
  return core.hl_rule(content, "Directory", apply_hl)
end, { cache_keys = { "directory" } })

