local M = {}

local config = require('bufswitch.config')
local core = require('bufswitch.core')
local tabline = require('bufswitch.tabline')
local utils = require('bufswitch.utils')

-- Module state
local initialized = false

-- Validate initialization state
local function ensure_initialized(operation_name)
  if not initialized then
    vim.notify(
      string.format("BufferSwitch error: %s called before setup(). Call require('bufferswitch').setup() first.",
        operation_name or "Operation"),
      vim.log.levels.ERROR
    )
    return false
  end
  return true
end

function M.setup(user_config)
  -- Clean up any existing setup
  if initialized then
    core.cleanup()
  end

  -- Create and validate configuration
  local setup_success, result = pcall(config.create, user_config)
  if not setup_success then
    vim.notify("BufferSwitch setup failed: " .. tostring(result), vim.log.levels.ERROR)
    return false
  end

  M.config = result

  -- Initialize core functionality
  local init_success = core.initialize(M.config)
  if not init_success then
    vim.notify("BufferSwitch core initialization failed", vim.log.levels.ERROR)
    return false
  end

  initialized = true

  -- Set up debug command if debugging is enabled
  if M.config.debug then
    local cmd_success, cmd_error = pcall(vim.api.nvim_create_user_command, 'BufferSwitcherDebug', function()
      core.debug_buffers()
    end, {
      desc = "Show BufferSwitch debug information"
    })

    if not cmd_success then
      vim.notify("Failed to create debug command: " .. tostring(cmd_error), vim.log.levels.WARN)
    end
  end

  return true
end

function M.set_debounce_delay(delay_ms)
  if not ensure_initialized("set_debounce_delay") then
    return false
  end

  if not delay_ms or type(delay_ms) ~= "number" then
    vim.notify("set_debounce_delay: delay_ms must be a number", vim.log.levels.ERROR)
    return false
  end

  return utils.set_debounce_delay(delay_ms)
end

function M.show_tabline(timeout)
  if not ensure_initialized("show_tabline") then
    return
  end

  if timeout and type(timeout) == "number" then
    M.config.hide_timeout = timeout
  end

  tabline.manage_tabline(M.config, core.get_buffer_order())
end

function M.hide_tabline()
  -- Allow this to work even if not initialized for cleanup purposes
  tabline.hide_tabline()
end

function M.force_refresh()
  if not ensure_initialized("force_refresh") then
    return
  end

  core.refresh_buffer_list()

  if M.config.show_tabline then
    tabline.manage_tabline(M.config, core.get_buffer_order())
  end
end

function M.goto_prev_buffer()
  if not ensure_initialized("goto_prev_buffer") then
    return
  end

  core.prev_buffer()
end

function M.goto_next_buffer()
  if not ensure_initialized("goto_next_buffer") then
    return
  end

  core.next_buffer()
end

-- Utility functions for external use
function M.get_buffer_order()
  if not ensure_initialized("get_buffer_order") then
    return {}
  end

  return core.get_buffer_order()
end

function M.is_initialized()
  return initialized
end

function M.get_config()
  if not ensure_initialized("get_config") then
    return nil
  end

  return vim.deepcopy(M.config) -- Return copy to prevent external modification
end

function M.is_special_buffer(bufnr)
  if not ensure_initialized("is_special_buffer") then
    return false
  end

  return utils.is_special_buffer(M.config, bufnr)
end

-- Reset debounce delay to default
function M.reset_debounce_delay()
  if not ensure_initialized("reset_debounce_delay") then
    return false
  end

  return utils.reset_debounce_delay()
end

-- Get current debounce delay
function M.get_debounce_delay()
  return utils.get_debounce_delay()
end

-- Manual cleanup function
function M.cleanup()
  if initialized then
    core.cleanup()
    initialized = false
    M.config = nil

    -- Remove debug command if it exists
    pcall(vim.api.nvim_del_user_command, 'BufferSwitcherDebug')
  end
end

-- Health check function for debugging
function M.health_check()
  local health = {
    initialized = initialized,
    config_valid = M.config ~= nil,
    core_initialized = initialized and core.is_initialized() or false,
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

-- Version information
M.version = "1.0.0"

return M
