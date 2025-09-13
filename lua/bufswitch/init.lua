local M = {}
local config = require('bufswitch.config')
local core = require('bufswitch.core')
local tabline = require('bufswitch.tabline')
local utils = require('bufswitch.utils')

local initialized = false

local function ensure_initialized(op)
  if not initialized then
    vim.notify(string.format("BufferSwitch error: %s called before setup()", op or "Operation"), vim.log.levels.ERROR)
    return false
  end
  return true
end

function M.setup(user_config)
  if initialized then
    core.cleanup()
  end

  M.config = config.create(user_config)
  if not core.initialize(M.config) then
    return false
  end

  initialized = true

  -- Set up key mappings for next/prev buffer navigation
  pcall(vim.keymap.set, 'n', M.config.next_key, M.goto_next_buffer, { desc = "Next buffer" })
  pcall(vim.keymap.set, 'n', M.config.prev_key, M.goto_prev_buffer, { desc = "Previous buffer" })

  if M.config.debug then
    vim.api.nvim_create_user_command('BufferSwitcherDebug', core.debug_buffers, { desc = "Show BufferSwitch debug info" })
  end

  return true
end

function M.set_debounce_delay(delay_ms)
  return ensure_initialized("set_debounce_delay") and utils.set_debounce_delay(delay_ms)
end

function M.show_tabline(timeout)
  if not ensure_initialized("show_tabline") then return end
  if timeout and type(timeout) == "number" then
    M.config.hide_timeout = timeout
  end
  tabline.manage_tabline(M.config, core.get_buffer_order())
end

function M.hide_tabline()
  tabline.hide_tabline()
end

function M.force_refresh()
  if not ensure_initialized("force_refresh") then return end
  core.refresh_buffer_list()
  if M.config.show_tabline then
    tabline.manage_tabline(M.config, core.get_buffer_order())
  end
end

function M.goto_prev_buffer()
  if ensure_initialized("goto_prev_buffer") then
    core.prev_buffer()
  end
end

function M.goto_next_buffer()
  if ensure_initialized("goto_next_buffer") then
    core.next_buffer()
  end
end

function M.get_buffer_order()
  return ensure_initialized("get_buffer_order") and core.get_buffer_order() or {}
end

function M.is_initialized()
  return initialized
end

function M.get_config()
  return ensure_initialized("get_config") and vim.deepcopy(M.config) or nil
end

function M.is_special_buffer(bufnr)
  return ensure_initialized("is_special_buffer") and utils.is_special_buffer(M.config, bufnr)
end

function M.reset_debounce_delay()
  return ensure_initialized("reset_debounce_delay") and utils.reset_debounce_delay()
end

function M.get_debounce_delay()
  return utils.get_debounce_delay()
end

function M.cleanup()
  if initialized then
    core.cleanup()
    initialized = false
    M.config = nil
    pcall(vim.api.nvim_del_user_command, 'BufferSwitcherDebug')
    pcall(vim.keymap.del, 'n', M.config.next_key)
    pcall(vim.keymap.del, 'n', M.config.prev_key)
  end
end

function M.health_check()
  local health = {
    initialized = initialized,
    config_valid = M.config ~= nil,
    core_initialized = initialized and core.is_initialized(),
    buffer_count = initialized and #core.get_buffer_order() or 0,
    debounce_delay = utils.get_debounce_delay(),
    current_tabline_state = vim.o.showtabline,
  }
  if initialized and M.config then
    health.show_tabline_config = M.config.show_tabline
    health.hide_timeout = M.config.hide_timeout
    health.debug_enabled = M.config.debug
  end
  return health
end

M.version = "1.0.0"
return M
