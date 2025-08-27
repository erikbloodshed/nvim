local M = {}

function M.get(c, o)
  local error = c.red
  local warn = c.yellow
  local info = c.sky
  local hint = c.teal
  local ok = c.green
  local t = o.transparency and c.none

  return {
    LspReferenceText = { bg = c.surface1 },
    LspReferenceRead = { link = "LspReferenceText" },
    LspReferenceWrite = { link = "LspReferenceText" },

    DiagnosticVirtualTextError = { bg = t or c.bg_dvt_error, fg = error, italic = true, },
    DiagnosticVirtualTextWarn = { bg = t or c.bg_dvt_warn, fg = warn, italic = true, },
    DiagnosticVirtualTextInfo = { bg = t or c.bg_dvt_info, fg = info, italic = true, },
    DiagnosticVirtualTextHint = { bg = t or c.bg_dvt_hint, fg = hint, italic = true, },
    DiagnosticVirtualTextOk = { bg = t or c.bg_dvt_ok, fg = ok, italic = true, },

    DiagnosticError = { fg = error, italic = true },
    DiagnosticWarn = { fg = warn, italic = true },
    DiagnosticInfo = { fg = info, italic = true },
    DiagnosticHint = { fg = hint, italic = true },
    DiagnosticOk = { fg = ok, italic = true },

    DiagnosticUnderlineError = { undercurl = true, sp = error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = warn },
    DiagnosticUnderlineInfo = { undercurl = true, sp = info },
    DiagnosticUnderlineHint = { undercurl = true, sp = hint },
    DiagnosticUnderlineOk = { undercurl = true, sp = ok },

    DiagnosticFloatingError = { fg = error },
    DiagnosticFloatingWarn = { fg = warn },
    DiagnosticFloatingInfo = { fg = info },
    DiagnosticFloatingHint = { fg = hint },
    DiagnosticFloatingOk = { fg = ok },

    DiagnosticSignError = { link = "DiagnosticFloatingError" },
    DiagnosticSignWarn = { link = "DiagnosticFloatingWarn" },
    DiagnosticSignInfo = { link = "DiagnosticFloatingInfo" },
    DiagnosticSignHint = { link = "DiagnosticFloatingHint" },
    DiagnosticSignOk = { link = "DiagnosticFloatingOk" },

    LspDiagnosticsDefaultError = { link = "DiagnosticFloatingError" },
    LspDiagnosticsDefaultWarning = { link = "DiagnosticFloatingWarn" },
    LspDiagnosticsDefaultInformation = { link = "DiagnosticFloatingInfo" },
    LspDiagnosticsDefaultHint = { link = "DiagnosticFloatingHint" },
    LspSignatureActiveParameter = { bg = c.surface0, bold = true },

    LspDiagnosticsError = { link = "DiagnosticFloatingError" },
    LspDiagnosticsWarning = { link = "DiagnosticFloatingWarn" },
    LspDiagnosticsInformation = { link = "DiagnosticFloatingInfo" },
    LspDiagnosticsHint = { link = "DiagnosticFloatingHint" },
    LspDiagnosticsVirtualTextError = { fg = error, italic = true },
    LspDiagnosticsVirtualTextWarning = { fg = warn, italic = true },
    LspDiagnosticsVirtualTextInformation = { fg = info, italic = true },
    LspDiagnosticsVirtualTextHint = { fg = hint, italic = true },
    LspDiagnosticsUnderlineError = { undercurl = true, sp = error },
    LspDiagnosticsUnderlineWarning = { undercurl = true, sp = warn },
    LspDiagnosticsUnderlineInformation = { undercurl = true, sp = info },
    LspDiagnosticsUnderlineHint = { undercurl = true, sp = hint },
    LspCodeLens = { fg = c.overlay0 },
    LspCodeLensSeparator = { link = "LspCodeLens" },
    LspInlayHint = { fg = c.overlay0, bg = t or c.bg_line },
    LspInfoBorder = { link = "FloatBorder" },
  }
end

return M
