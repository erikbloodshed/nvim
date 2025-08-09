-- statusline/profiler.lua
local M = {}

local config = require('statusline.config')

--[[
  Lightweight Profiling Storage
--]]
local profile = {
  times = {},
  counts = {},
  enabled = false
}

--[[
  Wrap a function with profiling
--]]
function M.wrap(component, fn)
  return function (...)
    local cfg = config.get()
    if not cfg or not cfg.enable_profiling then
      return fn(...)
    end

    local start = vim.loop.hrtime()
    local result = fn(...)
    local elapsed = (vim.loop.hrtime() - start) / 1e6 -- Convert to milliseconds

    -- Update profile data
    profile.times[component] = (profile.times[component] or 0) + elapsed
    profile.counts[component] = (profile.counts[component] or 0) + 1

    return result
  end
end

--[[
  Get profile data
--]]
function M.get_profile()
  if not config.get().enable_profiling then
    return { error = "Profiling is disabled" }
  end

  local result = {
    times = vim.deepcopy(profile.times),
    counts = vim.deepcopy(profile.counts),
    averages = {}
  }

  -- Calculate averages
  for component, total_time in pairs(profile.times) do
    local count = profile.counts[component] or 1
    result.averages[component] = total_time / count
  end

  return result
end

--[[
  Reset profile data
--]]
function M.reset()
  profile.times = {}
  profile.counts = {}
end

--[[
  Get formatted profile report
--]]
function M.get_report()
  local data = M.get_profile()
  if data.error then
    return data.error
  end

  local lines = { "=== Statusline Performance Report ===" }

  -- Sort components by total time
  local sorted_components = {}
  for component, _ in pairs(data.times) do
    table.insert(sorted_components, component)
  end

  table.sort(sorted_components, function (a, b)
    return data.times[a] > data.times[b]
  end)

  table.insert(lines, string.format("%-12s %8s %8s %8s",
    "Component", "Calls", "Total(ms)", "Avg(ms)"))
  table.insert(lines, string.rep("-", 40))

  for _, component in ipairs(sorted_components) do
    table.insert(lines, string.format("%-12s %8d %8.2f %8.2f",
      component,
      data.counts[component],
      data.times[component],
      data.averages[component]
    ))
  end

  return table.concat(lines, "\n")
end

--[[
  Print profile report
--]]
function M.print_report()
  print(M.get_report())
end

return M
