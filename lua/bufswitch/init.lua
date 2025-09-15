local M = {}

local user_config = {
  hide_timeout = 1000,
  tabline_display_window = 8, -- You can change this number
  wrap_around = true,
  debug = false,
}

local state = require('bufswitch.state')
state.init_config(user_config) -- Apply user config to the central state

require('bufswitch.core').init()

function M.goto_next_buffer()
  require('bufswitch.core').next_buffer()
end

function M.goto_prev_buffer()
  require('bufswitch.core').prev_buffer()
end

function M.alt_tab_buffer()
  require('bufswitch.core').alt_tab_buffer()
end

function M.show_tabline()
  require('bufswitch.core').show_tabline()
end

if state.config.debug then
  function M.debug_buffers()
    require('bufswitch.core').debug_buffers()
  end
end

return M
