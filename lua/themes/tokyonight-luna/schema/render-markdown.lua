local api = vim.api
local M = {}

M.get = function(c)
  local s = {
    RenderMarkdownBullet     = { fg = c.orange },
    RenderMarkdownCode       = { bg = c.bg_dark },
    RenderMarkdownDash       = { link = "RenderMarkdownBullet" },
    RenderMarkdownTableHead  = { fg = c.red },
    RenderMarkdownTableRow   = { link = "RenderMarkdownBullet" },
    RenderMarkdownCodeInline = { link = "@markup.raw.markdown_inline" }
  }

  ---@format disable-next
  local hl = api.nvim_set_hl
  for key, val in pairs(s) do hl(0, key, val) end
end

return M
