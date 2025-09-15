local utils = require("bufswitch.utils")
local state = require("bufswitch.state")
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local cache_ttl = 5000
local debounce_delay = 16

local caches = {
  bufname = {},
  devicon = {},
  tabline = { content = "", timestamp = 0, buffer_hash = "" },
}

local timers = {
  update = nil,
  cache_cleanup = nil,
}

local window_offset = 1

local function get_timestamp()
  return vim.loop.hrtime() / 1000000
end

local function is_cache_valid(timestamp, ttl)
  return get_timestamp() - timestamp < (ttl or cache_ttl)
end

local function hash_buffer_list(buffer_list, cycle_index)
  if not next(buffer_list) then return "" end
  local current_buf = vim.api.nvim_get_current_buf()
  local parts = { tostring(current_buf), tostring(cycle_index or 0), tostring(window_offset) }
  for _, bufnr in ipairs(buffer_list) do
    table.insert(parts, tostring(bufnr))
  end
  return table.concat(parts, "|")
end

local function get_cached_devicon(filename, filepath, is_current, base_hl)
  if not has_devicons then
    return ""
  end
  local basename = vim.fs.basename(filepath) or ""
  local ext = basename:match("%.([^%.]+)$") or ""
  local cache_key = filename .. ":" .. ext .. ":" .. (is_current and "1" or "0")
  local cached = caches.devicon[cache_key]
  if cached and is_cache_valid(cached.timestamp) then
    return cached.result
  end
  local devicon, icon_color = devicons.get_icon_color(filename, ext)
  local result = ""
  if devicon then
    local hl = vim.api.nvim_get_hl(0, { name = "PmenuSel" })
    vim.api.nvim_set_hl(0, "BufSwitchDevicon", { fg = icon_color, bg = hl.bg })
    local icon_hl = is_current and "BufSwitchDevicon" or "BufSwitchInactive"
    result = string.format("%%#%s#%s%%#%s# ", icon_hl, devicon, base_hl)
  end
  caches.devicon[cache_key] = { result = result, timestamp = get_timestamp() }
  return result
end

local format_bufname = function(bufnr, is_current)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return "[Invalid]"
  end
  local buftype = vim.bo[bufnr].buftype
  local cache_key = bufnr .. ":" .. (is_current and "1" or "0")
  local cached = caches.bufname[cache_key]
  if cached and is_cache_valid(cached.timestamp) then
    return cached.result
  end
  local name = vim.fn.bufname(bufnr)
  local display_name = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
  if buftype == "help" then
    display_name = "[Help] " .. (display_name ~= "" and display_name or "help")
  elseif buftype == "terminal" then
    display_name = "[Term] " .. (display_name ~= "" and display_name:gsub("^term://.*//", "") or "terminal")
  elseif display_name == "" then
    display_name = "[No Name]"
  end
  if #display_name > 16 then
    display_name = display_name:sub(1, 13) .. "..."
  end
  local base_hl = is_current and "BufSwitchSelected" or "BufSwitchInactive"
  local components = {}
  local devicon = get_cached_devicon(display_name, name, is_current, base_hl)
  if devicon ~= "" then
    table.insert(components, devicon)
  end
  table.insert(components, display_name)
  local result = table.concat(components)
  caches.bufname[cache_key] = { result = result, timestamp = get_timestamp() }
  return result
end

local M = {}

function M.update_tabline(buflist, cycle_index)
  local buffer_hash = hash_buffer_list(buflist, cycle_index)
  if caches.tabline.buffer_hash == buffer_hash and
    is_cache_valid(caches.tabline.timestamp, 100) then
    vim.o.tabline = caches.tabline.content
    return
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local parts = {}
  local total_buffers = #buflist
  local display_window = state.config.tabline_display_window -- Use central config

  if total_buffers == 0 then
    vim.o.tabline = "%#BufSwitchFill#%T"
    return
  end

  local current_index = 0

  -- If cycle_index is provided, use it directly as the position
  if cycle_index then
    current_index = cycle_index
  else
    -- Find the current buffer's position in the list
    for i, bufnr in ipairs(buflist) do
      if bufnr == current_buf then
        current_index = i
        break
      end
    end
    if current_index == 0 and total_buffers > 0 then current_index = 1 end
  end

  -- Determine start_index and end_index based on window_offset
  local start_index = window_offset
  local end_index = math.min(start_index + display_window - 1, total_buffers)

  -- Adjust window_offset when reaching the last or first viewable buffer
  if current_index > end_index and current_index <= total_buffers then
    -- Scroll right when navigating past the last viewable buffer
    window_offset = math.max(1, current_index - display_window + 1)
    start_index = window_offset
    end_index = math.min(start_index + display_window - 1, total_buffers)
  elseif current_index < start_index and current_index >= 1 then
    -- Scroll left when navigating before the first viewable buffer
    window_offset = math.max(1, current_index - display_window + 1)
    start_index = window_offset
    end_index = math.min(start_index + display_window - 1, total_buffers)
  end

  -- Only add "<.." if start_index > 1 and the current buffer is not the first buffer
  if start_index > 1 and current_index > 1 then
    table.insert(parts, "%#BufSwitchSeparator#<..")
  end

  for i = start_index, end_index do
    local bufnr = buflist[i]
    if vim.api.nvim_buf_is_valid(bufnr) then
      -- During cycling, highlight the buffer at cycle_index, otherwise highlight current_buf
      local is_current
      if cycle_index then
        is_current = (i == cycle_index)
      else
        is_current = (bufnr == current_buf)
      end

      local hl = is_current and "%#BufSwitchSelected#" or "%#BufSwitchInactive#"
      local entry = table.concat({ hl, "  ", format_bufname(bufnr, is_current), "  " })
      if i > start_index or (i == start_index and start_index > 1) then
        table.insert(parts, "%#BufSwitchSeparator#|")
      end
      table.insert(parts, entry)
    end
  end

  if end_index < total_buffers then
    table.insert(parts, "%#BufSwitchSeparator#|..>")
  end

  table.insert(parts, "%#BufSwitchFill#")
  local tabline_content = table.concat({ "%#BufSwitchFill#", table.concat(parts, ""), "%T" })
  caches.tabline.content = tabline_content
  caches.tabline.timestamp = get_timestamp()
  caches.tabline.buffer_hash = buffer_hash
  vim.o.tabline = tabline_content
end

local function update_tabline_debounced(buffer_list, cycle_index)
  if timers.update then
    timers.update:stop()
    timers.update:close()
  end
  timers.update = vim.defer_fn(function()
    M.update_tabline(buffer_list, cycle_index)
    timers.update = nil
  end, debounce_delay)
end

function M.show_tabline_temporarily(_, buffer_order)
  if state.config.hide_in_special and utils.is_special_buffer(state.config) then
    return
  end
  utils.stop_hide_timer()
  vim.o.showtabline = 2
  update_tabline_debounced(buffer_order)
  utils.start_hide_timer(state.config.hide_timeout, function()
    vim.o.showtabline = 0
  end)
end

function M.hide_tabline()
  vim.o.showtabline = 0
  utils.stop_hide_timer()
  if timers.update then
    timers.update:stop()
    timers.update:close()
    timers.update = nil
  end
end

local function cleanup_expired_cache()
  for key, entry in pairs(caches.bufname) do
    if not is_cache_valid(entry.timestamp, cache_ttl) then
      caches.bufname[key] = nil
    end
  end
  for key, entry in pairs(caches.devicon) do
    if not is_cache_valid(entry.timestamp, cache_ttl) then
      caches.devicon[key] = nil
    end
  end
end

local function invalidate_buffer_cache(bufnr)
  for key in pairs(caches.bufname) do
    if key:match("^" .. bufnr .. ":") then
      caches.bufname[key] = nil
    end
  end
  caches.tabline.buffer_hash = ""
end

local function setup_cache_management()
  timers.cache_cleanup = vim.fn.timer_start(30000, cleanup_expired_cache, { ['repeat'] = -1 })
  vim.api.nvim_create_autocmd({ "BufWritePost", "BufDelete", "BufModifiedSet" }, {
    callback = function(args)
      invalidate_buffer_cache(args.buf)
    end,
  })
end

setup_cache_management()
return M
