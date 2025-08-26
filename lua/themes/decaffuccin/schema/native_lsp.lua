local M = {}

function M.get(c, o, u)
  local error = c.red
  local warning = c.yellow
  local info = c.sky
  local hint = c.teal
  local ok = c.green
  local darkening_percentage = 0.095

  return {
    -- These groups are for the native LSP client. Some other LSP clients may
    -- use these groups, or use their own. Consult your LSP client's
    -- documentation.
    LspReferenceText = { bg = c.surface1 },  -- used for highlighting "text" references
    LspReferenceRead = { bg = c.surface1 },  -- used for highlighting "read" references
    LspReferenceWrite = { bg = c.surface1 }, -- used for highlighting "write" references
    -- highlight diagnostics in numberline

    DiagnosticVirtualTextError = {
      bg = o.transparent_background and c.none or u.darken(error, darkening_percentage, c.base),
      fg = error,
      italic = true,
    }, -- Used as the mantle highlight group. Other Diagnostic highlights link to this by default
    DiagnosticVirtualTextWarn = {
      bg = o.transparent_background and c.none or u.darken(warning, darkening_percentage, c.base),
      fg = warning,
      italic = true,
    }, -- Used as the mantle highlight group. Other Diagnostic highlights link to this by default
    DiagnosticVirtualTextInfo = {
      bg = o.transparent_background and c.none or u.darken(info, darkening_percentage, c.base),
      fg = info,
      italic = true,
    }, -- Used as the mantle highlight group. Other Diagnostic highlights link to this by default
    DiagnosticVirtualTextHint = {
      bg = o.transparent_background and c.none or u.darken(hint, darkening_percentage, c.base),
      fg = hint,
      italic = true,
    }, -- Used as the mantle highlight group. Other Diagnostic highlights link to this by default
    DiagnosticVirtualTextOk = {
      bg = o.transparent_background and c.none or u.darken(hint, darkening_percentage, c.base),
      fg = ok,
      italic = true,
    },                                                             -- Used as the mantle highlight group. Other Diagnostic highlights link to this by default

    DiagnosticError = { bg = c.none, fg = error, italic = true },  -- Used as the mantle highlight group. Other Diagnostic highlights link to this by default
    DiagnosticWarn = { bg = c.none, fg = warning, italic = true }, -- Used as the mantle highlight group. Other Diagnostic highlights link to this by default
    DiagnosticInfo = { bg = c.none, fg = info, italic = true },    -- Used as the mantle highlight group. Other Diagnostic highlights link to this by default
    DiagnosticHint = { bg = c.none, fg = hint, italic = true },    -- Used as the mantle highlight group. Other Diagnostic highlights link to this by default
    DiagnosticOk = { bg = c.none, fg = ok, italic = true },        -- Used as the mantle highlight group. Other Diagnostic highlights link to this by default

    DiagnosticUnderlineError = { undercurl = true, sp = error },   -- Used to underline "Error" diagnostics
    DiagnosticUnderlineWarn = { undercurl = true, sp = warning },  -- Used to underline "Warn" diagnostics
    DiagnosticUnderlineInfo = { undercurl = true, sp = info },     -- Used to underline "Info" diagnostics
    DiagnosticUnderlineHint = { undercurl = true, sp = hint },     -- Used to underline "Hint" diagnostics
    DiagnosticUnderlineOk = { undercurl = true, sp = ok },         -- Used to underline "Ok" diagnostics

    DiagnosticFloatingError = { fg = error },                      -- Used to color "Error" diagnostic messages in diagnostics float
    DiagnosticFloatingWarn = { fg = warning },                     -- Used to color "Warn" diagnostic messages in diagnostics float
    DiagnosticFloatingInfo = { fg = info },                        -- Used to color "Info" diagnostic messages in diagnostics float
    DiagnosticFloatingHint = { fg = hint },                        -- Used to color "Hint" diagnostic messages in diagnostics float
    DiagnosticFloatingOk = { fg = ok },                            -- Used to color "Ok" diagnostic messages in diagnostics float

    DiagnosticSignError = { fg = error },                          -- Used for "Error" signs in sign column
    DiagnosticSignWarn = { fg = warning },                         -- Used for "Warn" signs in sign column
    DiagnosticSignInfo = { fg = info },                            -- Used for "Info" signs in sign column
    DiagnosticSignHint = { fg = hint },                            -- Used for "Hint" signs in sign column
    DiagnosticSignOk = { fg = ok },                                -- Used for "Ok" signs in sign column

    LspDiagnosticsDefaultError = { fg = error },                   -- Used as the mantle highlight group. Other LspDiagnostic highlights link to this by default (except Underline)
    LspDiagnosticsDefaultWarning = { fg = warning },               -- Used as the mantle highlight group. Other LspDiagnostic highlights link to this by default (except Underline)
    LspDiagnosticsDefaultInformation = { fg = info },              -- Used as the mantle highlight group. Other LspDiagnostic highlights link to this by default (except Underline)
    LspDiagnosticsDefaultHint = { fg = hint },                     -- Used as the mantle highlight group. Other LspDiagnostic highlights link to this by default (except Underline)
    LspSignatureActiveParameter = { bg = c.surface0, bold = true },
    -- LspDiagnosticsFloatingError         = { }, -- Used to color "Error" diagnostic messages in diagnostics float
    -- LspDiagnosticsFloatingWarning       = { }, -- Used to color "Warning" diagnostic messages in diagnostics float
    -- LspDiagnosticsFloatingInformation   = { }, -- Used to color "Information" diagnostic messages in diagnostics float
    -- LspDiagnosticsFloatingHint          = { }, -- Used to color "Hint" diagnostic messages in diagnostics float

    LspDiagnosticsError = { fg = error },
    LspDiagnosticsWarning = { fg = warning },
    LspDiagnosticsInformation = { fg = info },
    LspDiagnosticsHint = { fg = hint },
    LspDiagnosticsVirtualTextError = { fg = error, italic = true },       -- Used for "Error" diagnostic virtual text
    LspDiagnosticsVirtualTextWarning = { fg = warning, italic = true },   -- Used for "Warning" diagnostic virtual text
    LspDiagnosticsVirtualTextInformation = { fg = info, italic = true },  -- Used for "Information" diagnostic virtual text
    LspDiagnosticsVirtualTextHint = { fg = hint, italic = true },         -- Used for "Hint" diagnostic virtual text
    LspDiagnosticsUnderlineError = { undercurl = true, sp = error },      -- Used to underline "Error" diagnostics
    LspDiagnosticsUnderlineWarning = { undercurl = true, sp = warning },  -- Used to underline "Warning" diagnostics
    LspDiagnosticsUnderlineInformation = { undercurl = true, sp = info }, -- Used to underline "Information" diagnostics
    LspDiagnosticsUnderlineHint = { undercurl = true, sp = hint },        -- Used to underline "Hint" diagnostics
    LspCodeLens = { fg = c.overlay0 },                                    -- virtual text of the codelens
    LspCodeLensSeparator = { link = "LspCodeLens" },                      -- virtual text of the codelens separators
    LspInlayHint = {
      -- fg of `Comment`
      fg = c.overlay0,
      -- bg of `CursorLine`
      bg = o.transparent_background and c.none
        or u.vary_color({ latte = u.lighten(c.mantle, 0.70, c.base) }, u.darken(c.surface0, 0.64, c.base)),
    },                                        -- virtual text of the inlay hints
    LspInfoBorder = { link = "FloatBorder" }, -- LspInfo border
  }
end

return M
