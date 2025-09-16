local api = vim.api
local utils = require('bufswitch.utils')
local state = require('bufswitch.state')
local events = require('bufswitch.event')

local M = {}

local autocmds_created = false
local config = state.config

-- New: Map to store the index of each buffer in the MRU list
local mru_index_map = {}

local function update_buffer_mru(bufnr)
  if not utils.should_include_buffer(config, bufnr) then return end

  -- Use hash map for faster removal
  if mru_index_map[bufnr] then
    table.remove(state.buffer_order, mru_index_map[bufnr])
  end

  table.insert(state.buffer_order, bufnr)
  -- Update the index map for all elements after the insertion
  for i, b in ipairs(state.buffer_order) do
    mru_index_map[b] = i
  end

  events.emit("BufferOrderUpdated", state.buffer_order, state.tabline_order)
end

local function remove_buffer_from_order(bufnr)
  -- Use hash map for faster removal
  if mru_index_map[bufnr] then
    table.remove(state.buffer_order, mru_index_map[bufnr])
    mru_index_map[bufnr] = nil
  end

  for i, b in ipairs(state.tabline_order) do
    if b == bufnr then
      table.remove(state.tabline_order, i)
      break
    end
  end
  events.emit("BufferOrderUpdated", state.buffer_order, state.tabline_order)
end

local function end_cycle()
  if not state.cycle.is_active then return end

  utils.stop_hide_timer()
  vim.o.showtabline = 0

  local final_bufnr = state.tabline_order[state.cycle.index]

  state.cycle.is_active = false
  state.cycle.index = 0

  if final_bufnr and api.nvim_buf_is_valid(final_bufnr) then
    update_buffer_mru(final_bufnr)
  end

  events.emit("CycleEnded")
end

local function navigate(direction)
  utils.stop_hide_timer()

  if not state.cycle.is_active then
    if #state.tabline_order < 2 then
      events.emit("ShowTablineTemporarily", state.tabline_order, nil)
      return
    end

    state.cycle.is_active = true

    local current_buf = api.nvim_get_current_buf()
    state.cycle.index = 0
    for i, bufnr in ipairs(state.tabline_order) do
      if bufnr == current_buf then
        state.cycle.index = i
        break
      end
    end

    if state.cycle.index == 0 then
      state.cycle.index = 1
    end
  end

  if direction == "prev" then
    if state.cycle.index <= 1 and not config.wrap_around then
      events.emit("ShowTablineTemporarily", state.tabline_order, nil)
      return
    end
    state.cycle.index = state.cycle.index - 1
    if state.cycle.index < 1 then
      state.cycle.index = #state.tabline_order
    end
  elseif direction == "next" then
    if state.cycle.index >= #state.tabline_order and not config.wrap_around then
      events.emit("ShowTablineTemporarily", state.tabline_order, nil)
      return
    end
    state.cycle.index = state.cycle.index + 1
    if state.cycle.index > #state.tabline_order then
      state.cycle.index = 1
    end
  elseif direction == "alt" then
    local mru_size = #state.buffer_order
    if mru_size < 2 then return end

    local current_buf = api.nvim_get_current_buf()
    local target_bufnr
    if current_buf == state.buffer_order[mru_size] then
      target_bufnr = state.buffer_order[mru_size - 1]
    else
      target_bufnr = state.buffer_order[mru_size]
    end

    state.cycle.index = 0
    for i, bufnr in ipairs(state.tabline_order) do
      if bufnr == target_bufnr then
        state.cycle.index = i
        break
      end
    end
    if state.cycle.index == 0 then return end
  end

  local target_bufnr = state.tabline_order[state.cycle.index]
  if not (target_bufnr and api.nvim_buf_is_valid(target_bufnr)) then
    end_cycle()
    return
  end

  vim.cmd('buffer ' .. target_bufnr)
  events.emit("CycleNavigation", state.tabline_order, state.cycle.index)
  utils.start_hide_timer(config.hide_timeout, end_cycle)
end

function M.alt_tab_buffer()
  if config.disable_in_special and utils.is_special_buffer(config) then return end
  navigate("alt")
end

function M.next_buffer()
  if config.disable_in_special and utils.is_special_buffer(config) then return end
  navigate("next")
end

function M.prev_buffer()
  if config.disable_in_special and utils.is_special_buffer(config) then return end
  navigate("prev")
end

function M.show_tabline()
  events.emit("ShowTablineStatic")
end

function M.debug_buffers()
  print("Current buffer order (MRU):")
  for i, bufnr in ipairs(state.buffer_order) do
    local name = vim.fn.bufname(bufnr) or "[No Name]"
    print(string.format("%d: %s (bufnr=%d) %s", i, name, bufnr, i == #state.buffer_order and "<- CURRENT" or ""))
  end
  print("\nTabline buffer order (Fixed):")
  for i, bufnr in ipairs(state.tabline_order) do
    local name = vim.fn.bufname(bufnr) or "[No Name]"
    print(string.format("%d: %s (bufnr=%d)", i, name, bufnr))
  end
end

local function setup_autocmds()
  if autocmds_created then return end
  local ag = api.nvim_create_augroup('BufferSwitcher', { clear = true })

  api.nvim_create_autocmd('BufEnter', {
    group = ag,
    callback = function()
      if state.cycle.is_active then return end
      update_buffer_mru(api.nvim_get_current_buf())
    end,
  })

  api.nvim_create_autocmd('BufAdd', {
    group = ag,
    callback = function(ev)
      if state.cycle.is_active then return end
      if utils.should_include_buffer(config, ev.buf) then
        table.insert(state.tabline_order, ev.buf)
        update_buffer_mru(ev.buf)
      end
    end,
  })

  api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = ag,
    callback = function(ev)
      remove_buffer_from_order(ev.buf)
    end,
  })

  autocmds_created = true
end

function M.init()
  state.buffer_order = {}
  state.tabline_order = {}
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if utils.should_include_buffer(config, bufnr) then
      table.insert(state.buffer_order, bufnr)
      table.insert(state.tabline_order, bufnr)
    end
  end
  update_buffer_mru(api.nvim_get_current_buf())
  setup_autocmds()
end

return M
