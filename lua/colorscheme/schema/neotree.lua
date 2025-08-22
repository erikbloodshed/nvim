local M = {}

M.get = function(c)
  return {
    NeoTreeDimText = { fg = c.fg_gutter },
    NeoTreeFileName = { fg = c.fg_dark },
    NeoTreeGitModified = { fg = c.orange },
    NeoTreeGitStaged = { fg = c.teal },
    NeoTreeGitUntracked = { fg = c.magenta },
    NeoTreeNormal = { link = "Normal" },
    NeoTreeNormalNC = { link = "NeoTreeNormalNC" },
    NeoTreeTabActive = { fg = c.blue, bg = c.bg_dark, bold = true },
    NeoTreeTabInactive = { fg = c.dark3, bg = c.dark },
    NeoTreeRootName = { fg = c.comment, bold = true },
    NeoTreeTabSeparatorActive = { fg = c.blue, bg = c.bg_dark },
    NeoTreeTabSeparatorInactive = { fg = c.bg, bg = c.dark },
  }
end

return M
