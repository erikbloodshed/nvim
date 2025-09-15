local utils = require("bufswitch.utils")
local state = require("bufswitch.state")
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

-- Configuration
local CACHE_TTL = 5000
local DEBOUNCE_DELAY = 16
local TABLINE_TTL = 100
local MAX_CACHE_SIZE = 100
local MAX_NAME_LENGTH = 16

-- Cache storage
local cache = {
  bufname = {},
  devicon = {},
  tabline = { content = "", timestamp = 0, hash = "" },
  static_tabline = { content = "", timestamp = 0, hash = "" }
}

-- Timers
local update_timer = nil

-- Initialize devicon highlight if available
if has_devicons then
  local hl = vim.api.nvim_get_hl(0, { name = "PmenuSel" })
  vim.api.nvim_set_hl(0, "BufSwitchDevicon", { fg = nil, bg = hl.bg })
end

-- Utility functions
local function get_timestamp()
  return vim.fn.reltimefloat(vim.fn.reltime()) * 1000
end

local function is_cache_valid(entry, ttl)
  return entry and (get_timestamp() - entry.timestamp < (ttl or CACHE_TTL))
end

local function create_cache_entry(result)
  return { result = result, timestamp = get_timestamp() }
end

-- Cache management
local function cleanup_cache_table(cache_table)
  local count = 0
  for _ in pairs(cache_table) do count = count + 1 end

  if count > MAX_CACHE_SIZE then
    for key, entry in pairs(cache_table) do
      if not is_cache_valid(entry) then
        cache_table[key] = nil
      end
    end
  end
end

local function cleanup_expired_cache()
  cleanup_cache_table(cache.bufname)
  cleanup_cache_table(cache.devicon)
end

local function invalidate_buffer_cache(bufnr)
  -- Clear buffer-specific cache entries
  for key in pairs(cache.bufname) do
    if key:match("^" .. bufnr .. ":") then
      cache.bufname[key] = nil
    end
  end
  -- Force tabline refresh
  cache.tabline.hash = ""
  cache.static_tabline.hash = ""
end

-- Buffer hash for cache invalidation
local function hash_buffer_list(buffer_list, cycle_index)
  if not next(buffer_list) then return "" end
  local current_buf = vim.api.nvim_get_current_buf()
  return string.format("%d:%d:%d", current_buf, cycle_index or 0, 1)
end

-- Devicon handling
local function get_devicon(filename, filepath, is_current, base_hl)
  if not has_devicons then return "" end

  local basename = vim.fs.basename(filepath) or ""
  local ext = basename:match("%.([^%.]+)$") or ""
  local cache_key = filename .. ":" .. ext .. ":" .. (is_current and "1" or "0")

  local cached = cache.devicon[cache_key]
  if is_cache_valid(cached) then
    return cached.result
  end

  local devicon, icon_color = devicons.get_icon_color(filename, ext)
  local result = ""

  if devicon then
    vim.api.nvim_set_hl(0, "BufSwitchDevicon", {
      fg = icon_color,
      bg = vim.api.nvim_get_hl(0, { name = "BufSwitchDevicon" }).bg
    })
    local icon_hl = is_current and "BufSwitchDevicon" or "BufSwitchInactive"
    result = string.format("%%#%s#%s%%#%s# ", icon_hl, devicon, base_hl)
  end

  cache.devicon[cache_key] = create_cache_entry(result)
  return result
end

-- Buffer name formatting
local function get_display_name(bufnr, name)
  local buftype = vim.bo[bufnr].buftype
  local display_name = vim.fs.basename(name) or "[No Name]"

  if buftype == "help" then
    display_name = "[Help] " .. (display_name ~= "[No Name]" and display_name or "help")
  elseif buftype == "terminal" then
    display_name = "[Term] " .. (display_name ~= "[No Name]" and display_name:gsub("^term://.*//", "") or "terminal")
  end

  if #display_name > MAX_NAME_LENGTH then
    display_name = display_name:sub(1, MAX_NAME_LENGTH - 3) .. "..."
  end

  return display_name
end

local function format_bufname(bufnr, is_current)
  local cache_key = bufnr .. ":" .. (is_current and "1" or "0")
  local cached = cache.bufname[cache_key]
  if is_cache_valid(cached) then
    return cached.result
  end

  local name = vim.api.nvim_buf_is_valid(bufnr) and vim.fn.bufname(bufnr) or ""
  if not name or name == "" then
    return "[Invalid]"
  end

  local display_name = get_display_name(bufnr, name)
  local base_hl = is_current and "BufSwitchSelected" or "BufSwitchInactive"
  local devicon = get_devicon(display_name, name, is_current, base_hl)
  local result = devicon .. display_name

  cache.bufname[cache_key] = create_cache_entry(result)
  return result
end

-- Calculate window bounds for buffer display
local function calculate_window_bounds(current_index, total_buffers, display_window)
  if total_buffers <= display_window then
    return 1, total_buffers
  end

  -- Default to showing first N buffers
  local start_index = 1

  -- Only scroll when current buffer would be outside the window
  if current_index > display_window then
    -- Scroll so current buffer appears at the rightmost position
    start_index = current_index - display_window + 1
  end

  -- Don't scroll past the end
  start_index = math.min(start_index, total_buffers - display_window + 1)
  local end_index = math.min(start_index + display_window - 1, total_buffers)

  return start_index, end_index
end

-- Find current buffer index
local function find_current_index(buffer_order, current_buf, cycle_index)
  if cycle_index then
    return cycle_index
  end

  for i, bufnr in ipairs(buffer_order) do
    if bufnr == current_buf then
      return i
    end
  end

  return #buffer_order > 0 and 1 or 0
end

-- Render tabline content
local function render_tabline(buffer_order, cycle_index, cache_ref, ttl)
  local buffer_hash = hash_buffer_list(buffer_order, cycle_index)

  -- Check cache
  if cache_ref.hash == buffer_hash and is_cache_valid(cache_ref, ttl) then
    return cache_ref.content
  end

  local total_buffers = #buffer_order
  if total_buffers == 0 then
    return "%#BufSwitchFill#%T"
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local current_index = find_current_index(buffer_order, current_buf, cycle_index)
  local display_window = state.config.tabline_display_window
  local start_index, end_index = calculate_window_bounds(current_index, total_buffers, display_window)

  -- Build tabline parts
  local parts = { "%#BufSwitchFill#" }

  -- Left truncation indicator
  if start_index > 1 then
    table.insert(parts, "%#BufSwitchSeparator#<..")
  end

  -- Buffer entries
  for i = start_index, end_index do
    local bufnr = buffer_order[i]
    if vim.api.nvim_buf_is_valid(bufnr) then
      local is_current = (cycle_index and i == cycle_index) or bufnr == current_buf
      local hl = is_current and "%#BufSwitchSelected#" or "%#BufSwitchInactive#"

      -- Add separator before entry (except for first)
      if i > start_index or (i == start_index and start_index > 1) then
        table.insert(parts, "%#BufSwitchSeparator#|")
      end

      table.insert(parts, hl .. "  " .. format_bufname(bufnr, is_current) .. "  ")
    end
  end

  -- Right truncation indicator
  if end_index < total_buffers then
    table.insert(parts, "%#BufSwitchSeparator#|..>")
  end

  table.insert(parts, "%#BufSwitchFill#%T")
  local tabline_content = table.concat(parts, "")

  -- Update cache
  cache_ref.content = tabline_content
  cache_ref.timestamp = get_timestamp()
  cache_ref.hash = buffer_hash

  return tabline_content
end

-- Public API implementation
local M = {}

function M.update_tabline(buflist, cycle_index)
  vim.o.tabline = render_tabline(buflist, cycle_index, cache.tabline, TABLINE_TTL)
end

-- Debounced update function
local function update_tabline_debounced(buffer_list, cycle_index)
  if not update_timer then
    update_timer = vim.loop.new_timer()
  end

  if update_timer then
    update_timer:stop()
    update_timer:start(DEBOUNCE_DELAY, 0, vim.schedule_wrap(function()
      M.update_tabline(buffer_list, cycle_index)
      if update_timer then
        update_timer:stop()
      end
    end))
  end
end

-- Show tabline with auto-hide
local function show_with_hide_timer(setter)
  if state.config.hide_in_special and utils.is_special_buffer(state.config) then
    return
  end

  utils.stop_hide_timer()
  vim.o.showtabline = 2
  setter()

  utils.start_hide_timer(state.config.hide_timeout, function()
    vim.o.showtabline = 0
  end)
end

function M.show_tabline_temporarily(_, buffer_order)
  show_with_hide_timer(function()
    update_tabline_debounced(buffer_order, nil)
  end)
end

function M.show_tabline_static()
  show_with_hide_timer(function()
    vim.o.tabline = render_tabline(state.tabline_order, nil, cache.static_tabline, TABLINE_TTL)
  end)
end

function M.hide_tabline()
  vim.o.showtabline = 0
  utils.stop_hide_timer()

  if update_timer then
    update_timer:stop()
    update_timer:close()
    update_timer = nil
  end
end

-- Setup cache management
local function setup_cache_management()
  vim.fn.timer_start(30000, cleanup_expired_cache, { ['repeat'] = -1 })
  vim.api.nvim_create_autocmd({ "BufWritePost", "BufDelete", "BufModifiedSet" }, {
    callback = function(args)
      invalidate_buffer_cache(args.buf)
    end,
  })
end

setup_cache_management()
return M
