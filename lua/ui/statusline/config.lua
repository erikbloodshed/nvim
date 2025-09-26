local icons = require("ui.icons")

local separator = " • "

local excluded = {
  buftype = {
    terminal = icons.terminal .. " terminal",
  },
  filetype = {
    ["neo-tree"] = icons.file_tree .. " neo-tree",
    ["neo-tree-popup"] = icons.file_tree .. " neo-tree",
    qf = icons.fix .. " quickfix",
    checkhealth = icons.status .. " checkhealth",
  },
}

local diags_tbl = {
  { icon = icons.error, hl = "DiagnosticError", severity_idx = 1 },
  { icon = icons.warn,  hl = "DiagnosticWarn",  severity_idx = 2 },
  { icon = icons.info,  hl = "DiagnosticInfo",  severity_idx = 3 },
  { icon = icons.hint,  hl = "DiagnosticHint",  severity_idx = 4 },
}

local modes_tbl = {
  n    = { text = " NOR ", hl = "StatusLineNormal" },
  i    = { text = " INS ", hl = "StatusLineInsert" },
  v    = { text = " VIS ", hl = "StatusLineVisual" },
  V    = { text = " V-L ", hl = "StatusLineVisual" },
  ["\22"] = { text = " V-B ", hl = "StatusLineVisual" },
  s    = { text = " SEL ", hl = "StatusLineSelect" },
  S    = { text = " S-L ", hl = "StatusLineSelect" },
  ["\19"] = { text = " S-B ", hl = "StatusLineSelect" },
  r    = { text = " REP ", hl = "StatusLineReplace" },
  R    = { text = " REP ", hl = "StatusLineReplace" },
  Rv   = { text = " R-V ", hl = "StatusLineReplace" },
  c    = { text = " CMD ", hl = "StatusLineCommand" },
  __index = function() return { text = " ??? ", hl = "StatusLineNormal" } end,
}
setmetatable(modes_tbl, modes_tbl)

return {
  separator = separator,
  excluded = excluded,
  diags_tbl = diags_tbl,
  modes_tbl = modes_tbl,
}

