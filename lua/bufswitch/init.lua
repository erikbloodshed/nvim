local M = {}

local user_config = {
  hide_timeout = 1000,
  tabline_display_window = 8,
  wrap_around = true,
  debug = false,
}

local state = require('bufswitch.state')
state.init_config(user_config)

require('bufswitch.core').init()

function M.goto_next_buf()
  require('bufswitch.core').next_buf()
end

function M.goto_prev_buf()
  require('bufswitch.core').prev_buf()
end

function M.recent_buf()
  require('bufswitch.core').recent_buf()
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
