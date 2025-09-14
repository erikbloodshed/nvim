local M = {}

local config = {
  hide_timeout = 800,
  show_tabline = true,
  hide_in_special = true,
  disable_in_special = true,
  periodic_cleanup = true,
  debug = false,

  special_buftypes = {
    "quickfix", "help", "nofile", "prompt", "terminal"
  },
  special_filetypes = {
    "qf", "help", "netrw", "neo-tree", "NvimTree"
  },
  special_bufname_patterns = {
    "^term://", "^neo%-tree "
  },
}

local core = require('bufswitch.core')
core.init(config)

function M.goto_next_buffer()
  core.next_buffer()
end

function M.goto_prev_buffer()
  core.prev_buffer()
end

function M.alt_tab_buffer()
  core.alt_tab_buffer()
end

if config.debug then
  function M.debug_buffers()
    core.debug_buffers()
  end
end

return M
