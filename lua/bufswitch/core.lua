local utils = require('bufswitch.utils')
local tabline = require('bufswitch.tabline')
local state = require('bufswitch.state')
local tbl_insert, tbl_remove = table.insert, table.remove
local api, fn = vim.api, vim.fn

local M = {}

local config = state.config

local function update_buffer_mru(bufnr)
  if not utils.include_buf(config, bufnr) then return end

  for i, buf in ipairs(state.buf_order) do
    if buf == bufnr then
      tbl_remove(state.buf_order, i)
      break
    end
  end
  tbl_insert(state.buf_order, bufnr)
end

local function remove_buf(bufnr)
  for i, b in ipairs(state.buf_order) do
    if b == bufnr then
      tbl_remove(state.buf_order, i)
      break
    end
  end
  for i, b in ipairs(state.tabline_order) do
    if b == bufnr then
      tbl_remove(state.tabline_order, i)
      break
    end
  end
end

local function end_cycle()
  if not state.cycle.active then return end

  utils.stop_hide_timer()
  vim.o.showtabline = 0

  local final_bufnr = state.tabline_order[state.cycle.index]

  state.cycle.active = false
  state.cycle.index = 0

  if final_bufnr and api.nvim_buf_is_valid(final_bufnr) then
    update_buffer_mru(final_bufnr)
  end

  if config.show_tabline then
    tabline.update_tabline(state.tabline_order)
  end
end

M.navigate = function(move)
  if config.disable_in_special and utils.is_special_buf(config) then return end
  utils.stop_hide_timer()

  if not state.cycle.active then
    if #state.tabline_order < 2 then
      tabline.show_temp_tabline(nil, state.tabline_order)
      return
    end

    state.cycle.active = true

    state.cycle.index = 0
    local current_buf = api.nvim_get_current_buf()
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

  if move == "prev" then
    if state.cycle.index <= 1 and not config.wrap_around then
      tabline.show_temp_tabline(nil, state.tabline_order)
      return
    end
    state.cycle.index = state.cycle.index - 1
    if state.cycle.index < 1 then
      state.cycle.index = #state.tabline_order
    end
  elseif move == "next" then
    if state.cycle.index >= #state.tabline_order and not config.wrap_around then
      tabline.show_temp_tabline(nil, state.tabline_order)
      return
    end
    state.cycle.index = state.cycle.index + 1
    if state.cycle.index > #state.tabline_order then
      state.cycle.index = 1
    end
  elseif move == "recent" then
    local mru_size = #state.buf_order
    if mru_size < 2 then return end

    local target_bufnr
    local current_buf = api.nvim_get_current_buf()
    if current_buf == state.buf_order[mru_size] then
      target_bufnr = state.buf_order[mru_size - 1]
    else
      target_bufnr = state.buf_order[mru_size]
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
  vim.o.showtabline = 2
  tabline.update_tabline(state.tabline_order, state.cycle.index)
  utils.start_hide_timer(config.hide_timeout, end_cycle)
end

function M.show_tabline()
  tabline.show_static_tabline()
end

function M.debug_bufs()
  print("Current buffer order (MRU):")
  for i, bufnr in ipairs(state.buf_order) do
    local name = fn.bufname(bufnr) or "[No Name]"
    print(string.format("%d: %s (bufnr=%d) %s", i, name, bufnr, i == #state.buf_order and "<- CURRENT" or ""))
  end
  print("\nTabline buffer order (Fixed):")
  for i, bufnr in ipairs(state.tabline_order) do
    local name = fn.bufname(bufnr) or "[No Name]"
    print(string.format("%d: %s (bufnr=%d)", i, name, bufnr))
  end
end

local autocmds_created = false

local function setup_autocmds()
  if autocmds_created then return end
  local ag = api.nvim_create_augroup('BufferSwitcher', { clear = true })

  api.nvim_create_autocmd('BufEnter', {
    group = ag,
    callback = function()
      vim.schedule(function()
        if state.cycle.active then return end
        update_buffer_mru(api.nvim_get_current_buf())
        if config.show_tabline then
          tabline.update_tabline(state.tabline_order)
        end
      end)
    end,
  })

  api.nvim_create_autocmd('BufAdd', {
    group = ag,
    callback = function(ev)
      vim.schedule(function()
        if state.cycle.active then return end
        if utils.include_buf(config, ev.buf) then
          tbl_insert(state.tabline_order, ev.buf)
          update_buffer_mru(ev.buf)
        end
      end)
    end,
  })

  api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = ag,
    callback = function(ev)
      remove_buf(ev.buf)
    end,
  })

  autocmds_created = true
end

function M.init()
  state.buf_order = {}
  state.tabline_order = {}
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if utils.include_buf(config, bufnr) then
      tbl_insert(state.buf_order, bufnr)
      tbl_insert(state.tabline_order, bufnr)
    end
  end
  update_buffer_mru(api.nvim_get_current_buf())
  setup_autocmds()
end

return M
