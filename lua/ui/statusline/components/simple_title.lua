local icons = require("ui.icons")

local titles_tbl = {
  buftype = { terminal = icons.terminal .. " terminal", popup = icons.dock .. " Popup" },
  filetype = {
    lazy = icons.sleep .. " Lazy",
    ["neo-tree"] = icons.file_tree .. " File Explorer",
    ["neo-tree-popup"] = icons.file_tree .. " File Explorer",
    lspinfo = icons.info .. " LSP Info",
    checkhealth = icons.status .. " Health",
    man = icons.book .. " Manual",
    qf = icons.fix .. " Quickfix",
    help = icons.help .. " Help",
  },
}

local M = {
  enabled = true,
  priority = 0,
  cache_keys = {},
}

function M.render(ctx, apply_hl)
  local conditional_hl = require('ui.statusline').conditional_hl
  local title = titles_tbl.buftype[ctx.bo.buftype] or titles_tbl.filetype[ctx.bo.filetype]
  return conditional_hl(title or "no file", "String", apply_hl)
end

return M
