local api, fn = vim.api, vim.fn
local ok, devicons = pcall(require, "nvim-web-devicons")

return {
  cache_keys = { "file_icon" },
  render = function(ctx, apply_hl)
    local data = ctx.cache:get("file_icon", function()
      local name = api.nvim_buf_get_name(ctx.bufnr)
      local key = (name == "") and "[No Name]" or fn.fnamemodify(name, ":t")
      local ext = (name == "") and "" or fn.fnamemodify(name, ":e")

      if ctx.win_data.icons[key] == nil then
        ctx.win_data.icons[key] = { icon = "", hl = "Normal" }
        vim.schedule(function()
          if not api.nvim_win_is_valid(ctx.winid) then return end
          if ok then
            local icon, hl = devicons.get_icon(key, ext)
            ctx.win_data.icons[key] = { icon = icon or "", hl = hl or "Normal" }
            ctx.cache:reset("file_icon")
            ctx.refresh_win(ctx.winid)
          end
        end)
      end

      return ctx.win_data.icons[key]
    end)

    return ctx.hl_rule(data.icon, data.hl, apply_hl) or ""
  end,
}
