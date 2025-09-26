local api = vim.api
local insert = table.insert

local state = require("ui.bufswitch.state")
local utils = require("ui.bufswitch.utils")

local M = {}

function M.update_mru(buf)
  if utils.should_include_buffer(buf) then
    utils.remove_item(state.data.buf_order, buf)
    insert(state.data.buf_order, 1, buf)
  end
end

function M.remove_buffer(buf)
  utils.remove_item(state.data.buf_order, buf)
  utils.remove_item(state.data.tabline_order, buf)
  return buf -- return for potential UI invalidation
end

function M.add_buffer(buf)
  if not state.is_cycling() and utils.should_include_buffer(buf) then
    insert(state.data.tabline_order, buf)
    M.update_mru(buf)
    return true
  end
  return false
end

function M.get_navigation_target(move)
  if move == "recent" then
    local n = #state.data.buf_order
    if n < 2 then return nil end
    local current = api.nvim_get_current_buf()
    local target = (current == state.data.buf_order[1])
      and state.data.buf_order[2] or state.data.buf_order[1]

    for i, b in ipairs(state.data.tabline_order) do
      if b == target then return i end
    end
  end
  return nil
end

function M.calculate_cycle_index(move, wrap_around)
  if move == "recent" then
    return M.get_navigation_target("recent")
  end

  local step = (move == "prev") and -1 or 1
  local new_index = state.data.cycle.index + step
  local max_index = #state.data.tabline_order

  if new_index < 1 then
    return wrap_around and max_index or nil
  elseif new_index > max_index then
    return wrap_around and 1 or nil
  end

  return new_index
end

function M.initialize_cycle()
  if state.is_cycling() then return false end

  if #state.data.tabline_order < 2 then return false end

  local current_buf = api.nvim_get_current_buf()
  local index = 0

  for i, b in ipairs(state.data.tabline_order) do
    if b == current_buf then
      index = i
      break
    end
  end

  if index == 0 then index = 1 end
  state.set_cycle(index)
  return true
end

return M
