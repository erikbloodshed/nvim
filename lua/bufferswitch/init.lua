-- BufferSwitcher: buffer switcher using NerdFont icons and temporary tabline
-- Main module that exposes the plugin API

local M = {}

-- Import modules
local config = require('bufferswitch.config')
local core = require('bufferswitch.core')
local tabline = require('bufferswitch.tabline')
local utils = require('bufferswitch.utils')

-- Setup function to initialize plugin with improved handling
function M.setup(user_config)
    -- Merge user config with defaults
    M.config = config.create(user_config)

    -- Set up initial buffer state and autocmds
    core.initialize(M.config)

    -- Debug command
    if M.config.debug then
        vim.api.nvim_create_user_command('BufferSwitcherDebug', core.debug_buffers, {})
    end
end

-- Make the debounce delay configurable
function M.set_debounce_delay(delay_ms)
    return utils.set_debounce_delay(delay_ms)
end

-- Manual control functions for user API
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
