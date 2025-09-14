local api = vim.api

local M = {}

local utils = require('bufswitch.utils')
local tabline = require('bufswitch.tabline')

local buffer_order = {}
local tabline_order = {}
local config = {}
local autocmds_created = false

local cycle = {
  is_active = false,
  index = 0,
}

local function update_buffer_mru(bufnr)
  if not utils.should_include_buffer(config, bufnr) then return end

  for i, b in ipairs(buffer_order) do
    if b == bufnr then
      table.remove(buffer_order, i)
      break
    end
  end
  table.insert(buffer_order, bufnr)
end

local function remove_buffer_from_order(bufnr)
  for i, b in ipairs(buffer_order) do
    if b == bufnr then
      table.remove(buffer_order, i)
      break
    end
  end
  for i, b in ipairs(tabline_order) do
    if b == bufnr then
      table.remove(tabline_order, i)
      break
    end
  end
end

local function end_cycle()
  if not cycle.is_active then return end

  utils.stop_hide_timer()
  vim.o.showtabline = 0

  local final_bufnr = tabline_order[cycle.index]

  cycle.is_active = false
  cycle.index = 0

  if final_bufnr and api.nvim_buf_is_valid(final_bufnr) then
    update_buffer_mru(final_bufnr)
  end

  if config.show_tabline then
    tabline.update_tabline(tabline_order)
  end
end

local function navigate(direction)
  utils.stop_hide_timer()

  if not cycle.is_active then
    if #tabline_order < 2 then
      vim.notify("No other buffers to switch to", vim.log.levels.INFO)
      return
    end

    cycle.is_active = true

    local current_buf = api.nvim_get_current_buf()
    cycle.index = 0
    for i, bufnr in ipairs(tabline_order) do
      if bufnr == current_buf then
        cycle.index = i
        break
      end
    end

    if cycle.index == 0 then
      cycle.index = 1
    end
  end

  if direction == "prev" then
    cycle.index = cycle.index - 1
    if cycle.index < 1 then cycle.index = #tabline_order end
  elseif direction == "next" then
    cycle.index = cycle.index + 1
    if cycle.index > #tabline_order then cycle.index = 1 end
  elseif direction == "alt" then
    local mru_order = {}
    for _, bufnr in ipairs(buffer_order) do
      table.insert(mru_order, bufnr)
    end
    local mru_size = #mru_order
    if mru_size < 2 then return end

    local current_buf = api.nvim_get_current_buf()
    local target_mru_index
    if current_buf == mru_order[mru_size] then
      target_mru_index = mru_size - 1
    else
      target_mru_index = mru_size
    end
    if target_mru_index < 1 then target_mru_index = 1 end

    local target_bufnr = mru_order[target_mru_index]

    cycle.index = 0
    for i, bufnr in ipairs(tabline_order) do
      if bufnr == target_bufnr then
        cycle.index = i
        break
      end
    end
    if cycle.index == 0 then
      return
    end
  end

  local target_bufnr = tabline_order[cycle.index]
  if not (target_bufnr and api.nvim_buf_is_valid(target_bufnr)) then
    end_cycle()
    return
  end

  vim.cmd('buffer ' .. target_bufnr)

  vim.o.showtabline = 2
  tabline.update_tabline(tabline_order)

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

function M.debug_buffers()
  print("Current buffer order (MRU):")
  for i, bufnr in ipairs(buffer_order) do
    local name = vim.fn.bufname(bufnr) or "[No Name]"
    print(string.format("%d: %s (bufnr=%d) %s", i, name, bufnr, i == #buffer_order and "<- CURRENT" or ""))
  end
  print("\nTabline buffer order (Fixed):")
  for i, bufnr in ipairs(tabline_order) do
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
      if cycle.is_active then return end

      update_buffer_mru(api.nvim_get_current_buf())

      if config.show_tabline then
        tabline.update_tabline(tabline_order)
      end
    end,
  })

  api.nvim_create_autocmd('BufAdd', {
    group = ag,
    callback = function(ev)
      if cycle.is_active then return end
      if utils.should_include_buffer(config, ev.buf) then
        table.insert(tabline_order, ev.buf) -- Add to fixed tabline order
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

function M.init(user_config)
  config = user_config
  buffer_order = {}
  tabline_order = {}
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if utils.should_include_buffer(config, bufnr) then
      table.insert(buffer_order, bufnr)
      table.insert(tabline_order, bufnr)
    end
  end
  update_buffer_mru(api.nvim_get_current_buf())
  setup_autocmds()
end

return M
