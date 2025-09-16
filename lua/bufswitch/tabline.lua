local utils = require("bufswitch.utils")
local state = require("bufswitch.state")
local events = require("bufswitch.event") -- New dependency
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local CACHE_TTL = 5000
local DEBOUNCE_DELAY = 16
local TABLINE_TTL = 100
local MAX_CACHE_SIZE = 100
local MAX_NAME_LENGTH = 16

local cache = {
  bufname = {},
  devicon = {},
  tabline = { content = "", timestamp = 0, hash = "", window_start = 1 },
  static_tabline = { content = "", timestamp = 0, hash = "", window_start = 1 }
}

local update_timer = nil
local config = state.config

if has_devicons then
  local hl = vim.api.nvim_get_hl(0, { name = "PmenuSel" })
  vim.api.nvim_set_hl(0, "BufSwitchDevicon", { fg = nil, bg = hl.bg })
end

local function get_timestamp()
  return vim.fn.reltimefloat(vim.fn.reltime()) * 1000
end

local function is_cache_valid(entry, ttl)
  return entry and (get_timestamp() - entry.timestamp < (ttl or CACHE_TTL))
end

local function create_cache_entry(result)
  return { result = result, timestamp = get_timestamp() }
end

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
  cache.bufname[bufnr] = nil
  cache.tabline.hash = ""
  cache.tabline.window_start = 1
  cache.static_tabline.hash = ""
  cache.static_tabline.window_start = 1
end

local function hash_buffer_list(buffer_list, cycle_index)
  if not next(buffer_list) then return "" end
  local current_buf = vim.api.nvim_get_current_buf()
  local list_string = vim.fn.join(buffer_list, ',')
  return string.format("%d:%d:%s", current_buf, cycle_index or 0, list_string)
end

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
  local cache_key = bufnr
  local cached = cache.bufname[cache_key]
  if is_cache_valid(cached) and cached.is_current == is_current then
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
  cache.bufname[cache_key].is_current = is_current
  return result
end

local function calculate_window_bounds(current_index, total_buffers, display_window, cache_ref)
  if total_buffers <= display_window then
    return 1, total_buffers
  end

  local window_start = cache_ref.window_start or 1
  local window_end = window_start + display_window - 1

  if current_index > window_end then
    window_start = current_index - display_window + 1
  elseif current_index < window_start then
    window_start = current_index
  end

  window_start = math.max(1, math.min(window_start, total_buffers - display_window + 1))
  local window_end_final = math.min(window_start + display_window - 1, total_buffers)

  cache_ref.window_start = window_start

  return window_start, window_end_final
end

local function find_current_index(buffer_order, current_buf, cycle_index, list_type)
  if cycle_index then
    return cycle_index
  end

  -- O(1) lookup when list type is known
  if list_type == "mru" then
    return state.get_buffer_mru_index(current_buf) or (#buffer_order > 0 and 1 or 0)
  elseif list_type == "tabline" then
    return state.get_buffer_tabline_index(current_buf) or (#buffer_order > 0 and 1 or 0)
  end

  -- Fallback for unknown list types
  for i, bufnr in ipairs(buffer_order) do
    if bufnr == current_buf then
      return i
    end
  end

  return #buffer_order > 0 and 1 or 0
end

local function render_tabline(buffer_order, cycle_index, cache_ref, ttl)
  local buffer_hash = hash_buffer_list(buffer_order, cycle_index)

  if cache_ref.hash == buffer_hash and is_cache_valid(cache_ref, ttl) then
    return cache_ref.content
  end

  local total_buffers = #buffer_order
  if total_buffers == 0 then
    return "%#BufSwitchFill#%T"
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local list_type = state.identify_buffer_list(buffer_order)
  local current_index = find_current_index(buffer_order, current_buf, cycle_index, list_type)
  local display_window = config.tabline_display_window
  local start_index, end_index = calculate_window_bounds(current_index, total_buffers, display_window, cache_ref)

  local parts = { "%#BufSwitchFill#" }

  if start_index > 1 then
    table.insert(parts, "%#BufSwitchSeparator#<..")
  end

  for i = start_index, end_index do
    local bufnr = buffer_order[i]
    if vim.api.nvim_buf_is_valid(bufnr) then
      local is_current = (cycle_index and i == cycle_index) or bufnr == current_buf
      local hl = is_current and "%#BufSwitchSelected#" or "%#BufSwitchInactive#"

      if i > start_index or (i == start_index and start_index > 1) then
        table.insert(parts, "%#BufSwitchSeparator#|")
      end

      table.insert(parts, hl .. "  " .. format_bufname(bufnr, is_current) .. "  ")
    end
  end

  if end_index < total_buffers then
    table.insert(parts, "%#BufSwitchSeparator#|..>")
  end

  table.insert(parts, "%#BufSwitchFill#%T")
  local tabline_content = table.concat(parts, "")

  cache_ref.content = tabline_content
  cache_ref.timestamp = get_timestamp()
  cache_ref.hash = buffer_hash

  return tabline_content
end

local M = {}

function M.update_tabline(buflist, cycle_index)
  vim.o.tabline = render_tabline(buflist, cycle_index, cache.tabline, TABLINE_TTL)
end

local function update_tabline_debounced(buffer_list, cycle_index)
  if not update_timer then
    update_timer = vim.uv.new_timer()
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

local function show_with_hide_timer(setter)
  if config.hide_in_special and utils.is_special_buffer(config) then
    return
  end

  utils.stop_hide_timer()
  vim.o.showtabline = 2
  setter()

  utils.start_hide_timer(config.hide_timeout, function()
    vim.o.showtabline = 0
  end)
end

local function setup_event_listeners()
  events.on("CycleNavigation", function(buflist, cycle_index)
    vim.o.showtabline = 2
    M.update_tabline(buflist, cycle_index)
  end)

  events.on("ShowTablineTemporarily", function(buflist, cycle_index)
    show_with_hide_timer(function()
      update_tabline_debounced(buflist, cycle_index)
    end)
  end)

  events.on("ShowTablineStatic", function()
    show_with_hide_timer(function()
      vim.o.tabline = render_tabline(state.tabline_order, nil, cache.static_tabline, TABLINE_TTL)
    end)
  end)

  events.on("CycleEnded", function()
    if config.show_tabline then
      M.update_tabline(state.tabline_order)
    end
  end)

  events.on("BufferOrderUpdated", function()
    if config.show_tabline then
      M.update_tabline(state.tabline_order)
    end
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

local function setup_cache_management()
  vim.fn.timer_start(30000, cleanup_expired_cache, { ['repeat'] = -1 })
  vim.api.nvim_create_autocmd({ "BufWritePost", "BufDelete", "BufModifiedSet" }, {
    callback = function(args)
      invalidate_buffer_cache(args.buf)
    end,
  })
end

setup_cache_management()
setup_event_listeners()
return M
