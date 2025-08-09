-- statusline/cache.lua
local M = {}

local config = require('statusline.config')

--[[
  Smart Cache with TTL and Width Caching
--]]
local cache = {
  data = {},
  last_update = {},
  widths = {},
}

--[[
  Check if cache entry is valid
--]]
function M.is_valid(component, force_refresh)
  if force_refresh or not cache.last_update[component] then
    return false
  end

  local intervals = config.get().cache.update_intervals
  local ttl = intervals[component] or 1000
  local now = vim.loop.hrtime() / 1e6

  return (now - cache.last_update[component]) < ttl and cache.data[component] ~= nil
end

--[[
  Update cache entry
--]]
function M.update(component, value)
  cache.data[component] = value
  cache.last_update[component] = vim.loop.hrtime() / 1e6

  -- Cache display width for performance
  local utils = require('statusline.utils')
  cache.widths[component] = utils.get_display_width(value)
end

--[[
  Get cached value
--]]
function M.get(component)
  return cache.data[component]
end

--[[
  Get cached width
--]]
function M.get_width(component)
  return cache.widths[component]
end

--[[
  Invalidate specific cache entry
--]]
function M.invalidate(component)
  cache.data[component] = nil
  cache.last_update[component] = nil
  cache.widths[component] = nil
end

--[[
  Invalidate cursor-related cache entries
--]]
function M.invalidate_cursor_related()
  M.invalidate('position')
  M.invalidate('percentage')
end

--[[
  Clear all cache
--]]
function M.clear()
  cache.data = {}
  cache.last_update = {}
  cache.widths = {}
end

--[[
  Get cache statistics for debugging
--]]
function M.get_stats()
  local stats = {
    entries = 0,
    total_size = 0,
  }

  for component, data in pairs(cache.data) do
    stats.entries = stats.entries + 1
    stats.total_size = stats.total_size + #tostring(data)
  end

  return stats
end

return M
