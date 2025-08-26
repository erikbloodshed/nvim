local M = {}

function M.get(c, o)
  local error = c.red
  local warning = c.yellow
  local info = c.sky
  local hint = c.teal
  local ok = c.green

  return {
    LspReferenceText = { bg = c.surface1 },
    LspReferenceRead = { bg = c.surface1 },
    LspReferenceWrite = { bg = c.surface1 },

    DiagnosticVirtualTextError = { bg = o.transparency and c.none or c.bg_dvt_error, fg = error, italic = true, },
    DiagnosticVirtualTextWarn = { bg = o.transparency and c.none or c.bg_dvt_warn, fg = warning, italic = true, },
    DiagnosticVirtualTextInfo = { bg = o.transparency and c.none or c.bg_dvt_info, fg = info, italic = true, },
    DiagnosticVirtualTextHint = { bg = o.transparency and c.none or c.bg_dvt_hint, fg = hint, italic = true, },
    DiagnosticVirtualTextOk = { bg = o.transparency and c.none or c.bg_dvt_ok, fg = ok, italic = true, },

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

    DiagnosticFloatingError = { fg = error },         -- Used to color "Error" diagnostic messages in diagnostics float
    DiagnosticFloatingWarn = { fg = warning },        -- Used to color "Warn" diagnostic messages in diagnostics float
    DiagnosticFloatingInfo = { fg = info },           -- Used to color "Info" diagnostic messages in diagnostics float
    DiagnosticFloatingHint = { fg = hint },           -- Used to color "Hint" diagnostic messages in diagnostics float
    DiagnosticFloatingOk = { fg = ok },               -- Used to color "Ok" diagnostic messages in diagnostics float

    DiagnosticSignError = { fg = error },             -- Used for "Error" signs in sign column
    DiagnosticSignWarn = { fg = warning },            -- Used for "Warn" signs in sign column
    DiagnosticSignInfo = { fg = info },               -- Used for "Info" signs in sign column
    DiagnosticSignHint = { fg = hint },               -- Used for "Hint" signs in sign column
    DiagnosticSignOk = { fg = ok },                   -- Used for "Ok" signs in sign column

    LspDiagnosticsDefaultError = { fg = error },      -- Used as the mantle highlight group. Other LspDiagnostic highlights link to this by default (except Underline)
    LspDiagnosticsDefaultWarning = { fg = warning },  -- Used as the mantle highlight group. Other LspDiagnostic highlights link to this by default (except Underline)
    LspDiagnosticsDefaultInformation = { fg = info }, -- Used as the mantle highlight group. Other LspDiagnostic highlights link to this by default (except Underline)
    LspDiagnosticsDefaultHint = { fg = hint },        -- Used as the mantle highlight group. Other LspDiagnostic highlights link to this by default (except Underline)
    LspSignatureActiveParameter = { bg = c.surface0, bold = true },
    -- LspDiagnosticsFloatingError         = { }, -- Used to color "Error" diagnostic messages in diagnostics float
    -- LspDiagnosticsFloatingWarning       = { }, -- Used to color "Warning" diagnostic messages in diagnostics float
    -- LspDiagnosticsFloatingInformation   = { }, -- Used to color "Information" diagnostic messages in diagnostics float
    -- LspDiagnosticsFloatingHint          = { }, -- Used to color "Hint" diagnostic messages in diagnostics float

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
    LspInlayHint = { fg = c.overlay0, bg = o.transparency and c.none or c.bg_line },
    LspInfoBorder = { link = "FloatBorder" },
  }
end

return M
