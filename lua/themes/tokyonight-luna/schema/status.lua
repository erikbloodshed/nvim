local api = vim.api
local M = {}

M.get = function(c)
  local g = {
    StatusLineNormal = { bg = c.blue, fg = c.black },
    StatusLineInsert = { bg = c.green, fg = c.black },
    StatusLineVisual = { bg = c.magenta, fg = c.black },
    StatusLineCommand = { bg = c.yellow, fg = c.black },
    StatusLineReplace = { bg = c.red, fg = c.black },
    StatusLineTerminal = { bg = c.green1, fg = c.black },
    StatusLineGit = { fg = c.orange },
    StatusLineModified = { fg = c.yellow },
    StatusLineFile = { fg = c.fg_dark },
    StatusLineDiagError = { link = "DiagnosticError" },
    StatusLineDiagWarning = { link = "DiagnosticWarn" },
    StatusLineDiagHint = { link = "DiagnosticHint" },
    StatusLineDiagInfo = { link = "DiagnosticInfo" },
    StatusLineLsp = { fg = c.green },
    StatusLineLabel = { fg = c.fg_dark },
    StatusLineValue = { fg = c.orange },
  }

  ---@format disable-next
  local hl = api.nvim_set_hl
  for k, v in pairs(g) do hl(0, k, v) end
end

return M
