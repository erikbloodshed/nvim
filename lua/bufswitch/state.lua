local M = {
  config = {
    hide_timeout = 800,
    show_tabline = true,
    hide_in_special = true,
    disable_in_special = true,
    periodic_cleanup = true,
    debug = false,
    tabline_display_window = 15,
    wrap_around = false,
    special_buftypes = { "quickfix", "help", "nofile", "prompt", "terminal" },
    special_filetypes = { "qf", "help", "netrw", "neo-tree", "NvimTree" },
    special_bufname_patterns = { "^term://", "^neo%-tree " },
  },

  buf_order = {},
  tabline_order = {},
  cycle = {
    active = false,
    index = 0,
  },
}

function M.init_config(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

return M
