local api = vim.api
local M = {}

M.get = function(c)
  local g = {
    NeoTreeDimText              = { fg = c.fg_gutter },
    NeoTreeFileName             = { fg = c.fg_dark },
    NeoTreeGitModified          = { fg = c.orange },
    NeoTreeGitStaged            = { fg = c.teal },
    NeoTreeGitUntracked         = { fg = c.magenta },
    NeoTreeNormal               = { link = "Normal" },
    NeoTreeNormalNC             = { link = "NeoTreeNormalNC" },
    NeoTreeTabActive            = { fg = c.blue, bg = c.bg_dark, bold = true },
    NeoTreeTabInactive          = { fg = c.dark3, bg = c.dark },
    NeoTreeRootName             = { fg = c.comment, bold = true },
    NeoTreeTabSeparatorActive   = { fg = c.blue, bg = c.bg_dark },
    NeoTreeTabSeparatorInactive = { fg = c.bg, bg = c.dark },
  }

  ---@format disable-next
  local hl = api.nvim_set_hl
  for k, v in pairs(g) do hl(0, k, v) end
end

return M
