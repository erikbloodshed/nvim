local M = {}

local config = require('bufferswitch.config')
local core = require('bufferswitch.core')
local tabline = require('bufferswitch.tabline')
local utils = require('bufferswitch.utils')

function M.setup(user_config)
  M.config = config.create(user_config)

  core.initialize(M.config)

  if M.config.debug then
    vim.api.nvim_create_user_command('BufferSwitcherDebug', core.debug_buffers, {})
  end
end

function M.set_debounce_delay(delay_ms)
  return utils.set_debounce_delay(delay_ms)
end

function M.show_tabline(timeout)
  if timeout then
    M.config.hide_timeout = timeout
  end
  tabline.manage_tabline(M.config)
end

function M.hide_tabline()
  tabline.hide_tabline()
end

function M.force_refresh()
  core.refresh_buffer_list()
  tabline.manage_tabline(M.config)
end

function M.goto_prev_buffer()
  M.setup()
  core.prev_buffer()
end

function M.goto_next_buffer()
  M.setup()
  core.next_buffer()
end

return M
