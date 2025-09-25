-- ui/statusline/cache.lua
local CacheManager = {}
CacheManager.__index = CacheManager

function CacheManager.new()
  return setmetatable({ cache = {} }, CacheManager)
end

function CacheManager:get(key, fnc)
  if self.cache[key] ~= nil then return self.cache[key] end
  local ok, res = pcall(fnc)
  self.cache[key] = ok and res or nil
  return self.cache[key]
end

function CacheManager:invalidate(keys)
  if type(keys) == "string" then
    self.cache[keys] = nil
  else
    for _, key in ipairs(keys) do self.cache[key] = nil end
  end
end

return CacheManager

