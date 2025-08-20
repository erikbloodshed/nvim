local api = vim.api
local blend = require("themes.util").blend
local hl = api.nvim_set_hl

local M = {}

M.get = function(c)
  local b = c.bg
  local g = {
    RenderMarkdownBullet     = { fg = c.orange },
    RenderMarkdownCode       = { bg = c.bg_dark },
    RenderMarkdownDash       = { link = "RenderMarkdownBullet" },
    RenderMarkdownTableHead  = { fg = c.red },
    RenderMarkdownTableRow   = { link = "RenderMarkdownBullet" },
    RenderMarkdownCodeInline = { link = "@markup.raw.markdown_inline" }
  }

  local rainbow = { c.blue, c.yellow, c.green, c.teal, c.magenta, c.purple, c.orange, c.red, }

  for key, val in pairs(g) do
    hl(0, key, val)
  end

  for i, v in ipairs(rainbow) do
    hl(0, "RenderMarkdownH" .. i .. "Bg", { bg = blend(v, 0.1, b) })
    hl(0, "RenderMarkdownH" .. i .. "Fg", { fg = v, bold = true })
  end
end

return M
