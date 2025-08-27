local M = {}

function M.get(c, o)
  local error = c.red
  local warning = c.yellow
  local info = c.sky
  local hint = c.teal
  local ok = c.green
  local transp = o.transparency and c.none

  return {
    LspReferenceText = { bg = c.surface1 },
    LspReferenceRead = { bg = c.surface1 },
    LspReferenceWrite = { bg = c.surface1 },

    DiagnosticVirtualTextError = { bg = transp or c.bg_dvt_error, fg = error, italic = true, },
    DiagnosticVirtualTextWarn = { bg = transp or c.bg_dvt_warn, fg = warning, italic = true, },
    DiagnosticVirtualTextInfo = { bg = transp or c.bg_dvt_info, fg = info, italic = true, },
    DiagnosticVirtualTextHint = { bg = transp or c.bg_dvt_hint, fg = hint, italic = true, },
    DiagnosticVirtualTextOk = { bg = transp or c.bg_dvt_ok, fg = ok, italic = true, },

    DiagnosticError = { bg = c.none, fg = error, italic = true },
    DiagnosticWarn = { bg = c.none, fg = warning, italic = true },
    DiagnosticInfo = { bg = c.none, fg = info, italic = true },
    DiagnosticHint = { bg = c.none, fg = hint, italic = true },
    DiagnosticOk = { bg = c.none, fg = ok, italic = true },

    DiagnosticUnderlineError = { undercurl = true, sp = error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = warning },
    DiagnosticUnderlineInfo = { undercurl = true, sp = info },
    DiagnosticUnderlineHint = { undercurl = true, sp = hint },
    DiagnosticUnderlineOk = { undercurl = true, sp = ok },

    DiagnosticFloatingError = { fg = error },
    DiagnosticFloatingWarn = { fg = warning },
    DiagnosticFloatingInfo = { fg = info },
    DiagnosticFloatingHint = { fg = hint },
    DiagnosticFloatingOk = { fg = ok },

    DiagnosticSignError = { fg = error },
    DiagnosticSignWarn = { fg = warning },
    DiagnosticSignInfo = { fg = info },
    DiagnosticSignHint = { fg = hint },
    DiagnosticSignOk = { fg = ok },

    LspDiagnosticsDefaultError = { fg = error },
    LspDiagnosticsDefaultWarning = { fg = warning },
    LspDiagnosticsDefaultInformation = { fg = info },
    LspDiagnosticsDefaultHint = { fg = hint },
    LspSignatureActiveParameter = { bg = c.surface0, bold = true },

    LspDiagnosticsError = { fg = error },
    LspDiagnosticsWarning = { fg = warning },
    LspDiagnosticsInformation = { fg = info },
    LspDiagnosticsHint = { fg = hint },
    LspDiagnosticsVirtualTextError = { fg = error, italic = true },
    LspDiagnosticsVirtualTextWarning = { fg = warning, italic = true },
    LspDiagnosticsVirtualTextInformation = { fg = info, italic = true },
    LspDiagnosticsVirtualTextHint = { fg = hint, italic = true },
    LspDiagnosticsUnderlineError = { undercurl = true, sp = error },
    LspDiagnosticsUnderlineWarning = { undercurl = true, sp = warning },
    LspDiagnosticsUnderlineInformation = { undercurl = true, sp = info },
    LspDiagnosticsUnderlineHint = { undercurl = true, sp = hint },
    LspCodeLens = { fg = c.overlay0 },
    LspCodeLensSeparator = { link = "LspCodeLens" },
    LspInlayHint = { fg = c.overlay0, bg = transp or c.bg_line },
    LspInfoBorder = { link = "FloatBorder" },
  }
end

return M
