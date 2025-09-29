-- config.lua
return {
  hide_timeout = 1000,
  show_tabline = true,
  disable_in_special = true,
  debug = false,
  tabline_display_window = 8,
  wrap_around = true,
  special_buftypes = { "quickfix", "help", "nofile", "prompt" },
  special_filetypes = { "qf", "help", "netrw", "neo-tree", "terminal" },
  special_bufname_patterns = { "^term://", "^neo%-tree " },
}

