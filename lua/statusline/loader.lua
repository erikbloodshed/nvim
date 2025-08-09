-- statusline/loader.lua
local M = {}

local config = require('statusline.config')

--[[
  Lazy Component Loader Class
--]]
local ComponentLoader = {}
ComponentLoader.__index = ComponentLoader

function ComponentLoader:new()
  return setmetatable({
    loaded_components = {},
    lazy_components = {},
    dependencies = {
      file_info = { 'nvim-web-devicons' },
      diagnostics = { 'vim.diagnostic' },
      lsp_status = { 'vim.lsp' }
    },
    dependency_cache = {}
  }, self)
end

--[[
  Check if a dependency is available
--]]
function ComponentLoader:is_dependency_available(dep)
  if self.dependency_cache[dep] ~= nil then
    return self.dependency_cache[dep]
  end

  local result
  if dep == 'vim.diagnostic' then
    result = vim.diagnostic ~= nil
  elseif dep == 'vim.lsp' then
    result = vim.lsp ~= nil
  else
    result = pcall(require, dep)
  end

  self.dependency_cache[dep] = result
  return result
end

--[[
  Check if all dependencies for a component are met
--]]
function ComponentLoader:check_dependencies(component)
  local deps = self.dependencies[component] or {}
  if #deps == 0 then return true end

  -- At least one dependency must be available
  for _, dep in ipairs(deps) do
    if self:is_dependency_available(dep) then
      return true
    end
  end

  return false
end

--[[
  Determine if a component should be loaded
--]]
function ComponentLoader:should_load_component(component)
  -- Already loaded
  if self.loaded_components[component] then
    return true
  end

  -- Disabled in config
  if not config.get().components[component] then
    return false
  end

  -- Dependencies not met
  if not self:check_dependencies(component) then
    self.lazy_components[component] = true
    return false
  end

  -- Mark as loaded
  self.loaded_components[component] = true
  self.lazy_components[component] = nil
  return true
end

--[[
  Check lazy components to see if dependencies are now available
--]]
function ComponentLoader:check_lazy_components()
  if next(self.lazy_components) == nil then
    return
  end

  for component, _ in pairs(self.lazy_components) do
    if self:check_dependencies(component) then
      self:should_load_component(component)
    end
  end
end

--[[
  Reset loader state
--]]
function ComponentLoader:reset()
  self.loaded_components = {}
  self.lazy_components = {}
  self.dependency_cache = {}
end

--[[
  Get loader status for debugging
--]]
function ComponentLoader:get_status()
  return {
    loaded = vim.deepcopy(self.loaded_components),
    lazy = vim.deepcopy(self.lazy_components),
    dependencies = vim.deepcopy(self.dependency_cache),
  }
end

-- Create singleton instance
local loader_instance = ComponentLoader:new()

-- Export loader methods
M.should_load_component = function (component)
  return loader_instance:should_load_component(component)
end

M.check_lazy_components = function ()
  return loader_instance:check_lazy_components()
end

M.reset = function ()
  return loader_instance:reset()
end

M.get_status = function ()
  return loader_instance:get_status()
end

return M
