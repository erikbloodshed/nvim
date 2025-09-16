local M = {}

local listeners = {}

function M.on(event_name, callback)
  if not listeners[event_name] then
    listeners[event_name] = {}
  end
  table.insert(listeners[event_name], callback)
end

function M.emit(event_name, ...)
  if listeners[event_name] then
    for _, callback in ipairs(listeners[event_name]) do
      callback(...)
    end
  end
end

return M
