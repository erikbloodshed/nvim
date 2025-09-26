local M = {}

M.config = {
  hide_timeout = 1000,
  show_tabline = true,
  hide_in_special = true,
  disable_in_special = true,
  periodic_cleanup = true,
  debug = false,
  tabline_display_window = 8,
  wrap_around = true,
  special_buftypes = { "quickfix", "help", "nofile", "prompt" },
  special_filetypes = { "qf", "help", "netrw", "neo-tree", "terminal" },
  special_bufname_patterns = { "^term://", "^neo%-tree " },
}

return M
