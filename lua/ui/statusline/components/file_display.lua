local api, fn = vim.api, vim.fn

local M = {
  enabled = true,
  priority = 8,
  cache_keys = { "file_data" },
}

function M.render(ctx, apply_hl)
  local conditional_hl = require('ui.statusline').conditional_hl
  local refresh_win = require('ui.statusline').refresh_win

  local file_data = ctx.cache:get("file_data", function()
    local name = api.nvim_buf_get_name(ctx.bufnr)
    local fname = (name == "") and "[No Name]" or fn.fnamemodify(name, ":t")
    local ext = (name == "") and "" or fn.fnamemodify(name, ":e")
    local key = fname .. "." .. ext
    if ctx.wdata.icons[key] == nil then
      ctx.wdata.icons[key] = { icon = "", hl = "Normal" }
      vim.schedule(function()
        if not api.nvim_win_is_valid(ctx.winid) then return end
        local ok, devicons = pcall(require, "nvim-web-devicons")
        if ok then
          local icon, hl = devicons.get_icon(fname, ext)
          ctx.wdata.icons[key] = {
            icon = icon or "",
            hl = hl or "Normal"
          }
          ctx.cache:invalidate("file_data")
          refresh_win(ctx.winid)
        end
      end)
    end
    local icon_info = ctx.wdata.icons[key]
    return {
      name = fname,
      icon = icon_info.icon,
      hl = icon_info.hl
    }
  end)

  local parts = {}
  if file_data.icon and file_data.icon ~= "" then
    parts[#parts + 1] = conditional_hl(file_data.icon, file_data.hl, apply_hl)
    parts[#parts + 1] = " "
  end
  parts[#parts + 1] = conditional_hl(file_data.name, "StatusLine", apply_hl)
  return table.concat(parts, "")
end

return M
