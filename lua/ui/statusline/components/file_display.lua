local api, fn = vim.api, vim.fn
local core = require("ui.statusline.core")
local cmp = require("ui.statusline.cmp")

cmp.register_cmp("file_display", function(ctx, apply_hl)
  local file_data = ctx.cache:get("file_data", function()
    local name = api.nvim_buf_get_name(ctx.bufnr)
    local key = (name == "") and "[No Name]" or fn.fnamemodify(name, ":t")
    local ext = (name == "") and "" or fn.fnamemodify(name, ":e")
    if ctx.windat.icons[key] == nil then
      ctx.windat.icons[key] = { icon = "", hl = "Normal" }
      vim.schedule(function()
        if not api.nvim_win_is_valid(ctx.winid) then return end
        local ok, devicons = pcall(require, "nvim-web-devicons")
        if ok then
          local icon, hl = devicons.get_icon(key, ext)
          ctx.windat.icons[key] = {
            icon = icon or "",
            hl = hl or "Normal",
          }
          ctx.cache:reset("file_data")
          core.refresh_win(ctx.winid)
        end
      end)
    end
    local icon_info = ctx.windat.icons[key]
    return { name = key, icon = icon_info.icon, hl = icon_info.hl }
  end)

  local parts = {}
  if file_data.icon and file_data.icon ~= "" then
    parts[#parts + 1] = core.hl_rule(file_data.icon, file_data.hl, apply_hl)
    parts[#parts + 1] = " "
  end
  parts[#parts + 1] = core.hl_rule(file_data.name, "StatusLine", apply_hl)
  return table.concat(parts, "")
end, { cache_keys = { "file_data" } })

