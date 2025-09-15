local M = {}

-- Your personal configuration goes here.
-- Any option you don't set will use the default from state.lua.
local user_config = {
  hide_timeout = 1000,
  tabline_display_window = 10, -- You can change this number
  debug = false,
}

-- Centralized state management
local state = require('bufswitch.state')
state.init_config(user_config) -- Apply user config to the central state

-- Initialize the plugin's core logic
require('bufswitch.core').init()

-- Export functions for keymaps
function M.goto_next_buffer()
  require('bufswitch.core').next_buffer()
end

function M.goto_prev_buffer()
  require('bufswitch.core').prev_buffer()
end

function M.alt_tab_buffer()
  require('bufswitch.core').alt_tab_buffer()
end

if state.config.debug then
  function M.debug_buffers()
    require('bufswitch.core').debug_buffers()
  end
end

return M
