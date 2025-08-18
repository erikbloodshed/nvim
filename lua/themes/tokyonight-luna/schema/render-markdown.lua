local api = vim.api
local blend_bg = require("themes.util").blend_bg
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
  for i, color in ipairs(c.rainbow) do
    hl(0, "RenderMarkdownH" .. i .. "Bg", { bg = blend_bg(color, 0.1, c.bg) })
    hl(0, "RenderMarkdownH" .. i .. "Fg", { fg = color, bold = true })
  end
end

return M
