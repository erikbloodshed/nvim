-- core.lua

local M = {}

local utils = require('bufferswitch.utils')
local tabline = require('bufferswitch.tabline')

-- The master list of buffers, always in Most-Recently-Used order.
local buffer_order = {}
-- Static list for tabline display, order does not change with navigation.
local tabline_order = {}
local config = {}
local autocmds_created = false

-- State for managing the "switching mode" when the tabline is temporarily visible.
local cycle = {
  is_active = false, -- Is the user currently cycling through buffers?
  index = 0,         -- The currently selected buffer's index in tabline_order.
}

--[[
  Main Buffer List Management
--]]

-- Moves a buffer to the end of the main `buffer_order` list, marking it as most recent.
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

-- Removes a buffer from the main `buffer_order` and `tabline_order` lists (e.g., on BufDelete).
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

--[[
  "Switching Mode" Cycle Management
--]]

-- Ends the current switching cycle. This is called by the hide timer.
local function end_cycle()
  if not cycle.is_active then return end

  -- 1. Stop the timer and hide the tabline.
  utils.stop_hide_timer()
  vim.o.showtabline = 0

  -- 2. Get the buffer that the user finally landed on.
  local final_bufnr = tabline_order[cycle.index]

  -- 3. IMPORTANT: Reset the cycle state *before* doing anything else.
  cycle.is_active = false
  cycle.index = 0

  -- 4. "Commit" the change: Update the main MRU list with the final selection.
  if final_bufnr and vim.api.nvim_buf_is_valid(final_bufnr) then
    update_buffer_mru(final_bufnr)
  end

  -- 5. Update the tabline with the static tabline_order if needed.
  if config.show_tabline then
    tabline.update_tabline(tabline_order)
  end
end

-- This is the core function that handles all navigation.
-- It either starts a new cycle or continues an existing one.
local function navigate(direction)
  -- Any navigation command should reset the hide timer.
  utils.stop_hide_timer()

  if not cycle.is_active then
    -- This is the START of a new cycle.
    if #tabline_order < 2 then
      vim.notify("No other buffers to switch to", vim.log.levels.INFO)
      return
    end

    -- 1. Activate the "switching mode".
    cycle.is_active = true

    -- 2. Find the current buffer's index in tabline_order.
    local current_buf = vim.api.nvim_get_current_buf()
    cycle.index = 0
    for i, bufnr in ipairs(tabline_order) do
      if bufnr == current_buf then
        cycle.index = i
        break
      end
    end
    -- If current buffer not in tabline_order, start at first valid buffer.
    if cycle.index == 0 then
      cycle.index = 1
    end
  end

  -- We are now in a cycle. Let's find the next buffer to highlight.
  if direction == "prev" then
    -- Move to previous buffer in tabline_order.
    cycle.index = cycle.index - 1
    if cycle.index < 1 then cycle.index = #tabline_order end -- Wrap around
  elseif direction == "next" then
    -- Move to next buffer in tabline_order.
    cycle.index = cycle.index + 1
    if cycle.index > #tabline_order then cycle.index = 1 end -- Wrap around
  elseif direction == "alt" then
    -- Toggle between the two most recent buffers in buffer_order
    local mru_order = {}
    for _, bufnr in ipairs(buffer_order) do
      table.insert(mru_order, bufnr)
    end
    local mru_size = #mru_order
    if mru_size < 2 then return end -- Not enough buffers to toggle

    local current_buf = vim.api.nvim_get_current_buf()
    local target_mru_index
    if current_buf == mru_order[mru_size] then
      target_mru_index = mru_size - 1
    else
      target_mru_index = mru_size
    end
    if target_mru_index < 1 then target_mru_index = 1 end

    local target_bufnr = mru_order[target_mru_index]

    -- Find the index of target_bufnr in tabline_order and update cycle.index
    cycle.index = 0
    for i, bufnr in ipairs(tabline_order) do
      if bufnr == target_bufnr then
        cycle.index = i
        break
      end
    end
    if cycle.index == 0 then
      -- If not found (unlikely), fall back to current index
      return
    end
  end

  local target_bufnr = tabline_order[cycle.index]
  if not (target_bufnr and vim.api.nvim_buf_is_valid(target_bufnr)) then
    end_cycle() -- End cycle safely if buffer became invalid.
    return
  end

  -- Switch to the target buffer. The BufEnter event is guarded by `cycle.is_active`.
  vim.cmd('buffer ' .. target_bufnr)

  -- Display the tabline using the static `tabline_order` list.
  vim.o.showtabline = 2
  tabline.update_tabline(tabline_order)

  -- Start the timer that will eventually call `end_cycle` to exit the mode.
  utils.start_hide_timer(config.hide_timeout, end_cycle)
end

--[[
  Plugin Setup and Public Functions
--]]

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
  local ag = vim.api.nvim_create_augroup('BufferSwitcher', { clear = true })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = ag,
    callback = function()
      -- CRITICAL: When in a switching cycle, we must NOT modify the main MRU list.
      if cycle.is_active then return end

      update_buffer_mru(vim.api.nvim_get_current_buf())

      if config.show_tabline then
        tabline.update_tabline(tabline_order)
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufAdd', {
    group = ag,
    callback = function(ev)
      if cycle.is_active then return end
      if utils.should_include_buffer(config, ev.buf) then
        table.insert(tabline_order, ev.buf) -- Add to fixed tabline order
        update_buffer_mru(ev.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = ag,
    callback = function(ev)
      remove_buffer_from_order(ev.buf)
    end,
  })

  autocmds_created = true
end

function M.initialize(user_config)
  config = user_config
  buffer_order = {}
  tabline_order = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if utils.should_include_buffer(config, bufnr) then
      table.insert(buffer_order, bufnr)
      table.insert(tabline_order, bufnr)
    end
  end
  update_buffer_mru(vim.api.nvim_get_current_buf())
  setup_autocmds()
end

return M
