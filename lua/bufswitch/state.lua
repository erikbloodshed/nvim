local M = {
  -- All configuration options with their default values
  config = {
    hide_timeout = 800,
    show_tabline = true,
    hide_in_special = true,
    disable_in_special = true,
    periodic_cleanup = true,
    debug = false,
    tabline_display_window = 15, -- The key option for scrolling
    special_buftypes = { "quickfix", "help", "nofile", "prompt", "terminal" },
    special_filetypes = { "qf", "help", "netrw", "neo-tree", "NvimTree" },
    special_bufname_patterns = { "^term://", "^neo%-tree " },
  },

  -- Live state tables that will be managed by the plugin
  buffer_order = {}, -- MRU (Most Recently Used) buffer list
  tabline_order = {}, -- Fixed-order list for the tabline display
  cycle = {
    is_active = false,
    index = 0,
  },
}

-- This function will merge the user's config with the defaults
function M.init_config(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

return M
