local M = {}

function M.create(user_config)
  local default_config = {
    hide_timeout = 800,
    show_tabline = true,
    next_key = '<Right>',
    prev_key = '<Left>',
    orig_next_key = nil,
    orig_prev_key = nil,
    hide_in_special = true,
    disable_in_special = true,
    passthrough_keys_in_special = false,
    special_buftypes = {
      "quickfix", "help", "nofile", "prompt",
    },
    special_filetypes = {
      "qf", "help", "netrw", "fugitive", "NvimTree", "neo-tree",
      "nerdtree", "fern", "CHADTree", "Trouble", "dirvish"
    },
    special_bufname_patterns = {
      "^term://", "^fugitive://", "^neo%-tree "
    },
    exclude_buftypes = {
      "quickfix", "nofile", "help", "prompt"
    },
    exclude_filetypes = {
      "qf", "netrw", "Trouble", "fugitive", "NvimTree"
    },
    periodic_cleanup = true,
    debug = false,
  }

  if user_config then
    return vim.tbl_deep_extend('force', default_config, user_config)
  end

  return default_config
end

return M
