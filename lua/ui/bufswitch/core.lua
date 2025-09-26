local api = vim.api

local config = require("ui.bufswitch.config")
local state = require("ui.bufswitch.state")
local utils = require("ui.bufswitch.utils")
local buffer_manager = require("ui.bufswitch.buffer_manager")
local ui = require("ui.bufswitch.ui")

local M = {}

-- Navigation logic
local function end_cycle()
  if not state.is_cycling() then return end

  ui.stop_timer()
  ui.hide_tabline()

  local target_buf = state.data.tabline_order[state.data.cycle.index]
  state.reset_cycle()

  if target_buf and api.nvim_buf_is_valid(target_buf) then
    buffer_manager.update_mru(target_buf)
  end

  if config.show_tabline then
    ui.update_tabline(state.data.tabline_order, nil, utils.should_apply_hl())
  end
end

function M.navigate(move)
  if config.disable_in_special and utils.is_special() then return end

  ui.stop_timer()
  local apply_hl = utils.should_apply_hl()

  -- Initialize cycle if not active
  if not state.is_cycling() then
    if not buffer_manager.initialize_cycle() then
      ui.show_temporary_tabline(state.data.tabline_order, apply_hl)
      return
    end
  end

  -- Calculate new index
  local new_index = buffer_manager.calculate_cycle_index(move, config.wrap_around)
  if not new_index then
    ui.show_temporary_tabline(state.data.tabline_order, apply_hl)
    return
  end

  state.data.cycle.index = new_index
  local target_buf = state.data.tabline_order[new_index]

  if not (target_buf and api.nvim_buf_is_valid(target_buf)) then
    end_cycle()
    return
  end

  vim.cmd('buffer ' .. target_buf)
  ui.show_tabline()
  ui.update_tabline(state.data.tabline_order, new_index, apply_hl)
  ui.start_timer(config.hide_timeout, end_cycle)
end

-- Buffer event handlers
function M.on_buffer_enter(buf)
  if not state.is_cycling() then
    buffer_manager.update_mru(buf)
    if config.show_tabline then
      local apply_hl = api.nvim_win_is_valid(api.nvim_get_current_win())
      ui.update_tabline(state.data.tabline_order, nil, apply_hl)
    end
  end
end

function M.on_buffer_add(buf)
  buffer_manager.add_buffer(buf)
end

function M.on_buffer_remove(buf)
  local removed_buf = buffer_manager.remove_buffer(buf)
  ui.invalidate_buffer(removed_buf)
end

function M.on_buffer_modify(buf)
  ui.invalidate_buffer(buf)
end

-- Public API
function M.get_state()
  return state.data
end

return M
