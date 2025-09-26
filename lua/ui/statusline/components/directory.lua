local api, fn = vim.api, vim.fn
local icons = require("ui.icons")
local core = require("ui.statusline.core")

local function shorten_path(path)
  return path:gsub("([^/]+)/", function(dir)
    if dir == "~" then return dir .. "/" end
    local str = dir:sub(1, 1)
    if str == "." then return "." .. dir:sub(2, 2) .. "/" end
    return str .. "/"
  end)
end

return {
  cache_keys = { "diagnostics" },
  render = function(ctx, apply_hl)
    local path = ctx.cache:get("directory", function()
      local buf_name = api.nvim_buf_get_name(ctx.bufnr)
      return (buf_name == "") and fn.getcwd() or fn.fnamemodify(buf_name, ":p:h")
    end)
    if not path or path == "" then return "" end
    local display_name = shorten_path(fn.fnamemodify(path, ":~"))
    local content = icons.folder .. " " .. display_name
    return core.hl_rule(content, "Directory", apply_hl)
  end,
}
