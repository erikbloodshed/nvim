local utils = require("bufswitch.utils")
local state = require("bufswitch.state")
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local cache_ttl = 5000
local debounce_delay = 16

local caches = {
  bufname = {},
  devicon = {},
  tabline = { content = "", timestamp = 0, buffer_hash = "" },
  static_tabline = { content = "", timestamp = 0, buffer_hash = "" }
}

local timers = {
  update = nil,
}

local window_offset = 1

if has_devicons then
  local hl = vim.api.nvim_get_hl(0, { name = "PmenuSel" })
  vim.api.nvim_set_hl(0, "BufSwitchDevicon", { fg = nil, bg = hl.bg })
end

local function get_timestamp()
  return vim.fn.reltimefloat(vim.fn.reltime()) * 1000
end

local function is_cache_valid(timestamp, ttl)
  return get_timestamp() - timestamp < (ttl or cache_ttl)
end

local function hash_buffer_list(buffer_list, cycle_index)
  if not next(buffer_list) then return "" end
  local current_buf = vim.api.nvim_get_current_buf()
  return string.format("%d:%d:%d", current_buf, cycle_index or 0, window_offset)
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
    vim.api.nvim_set_hl(0, "BufSwitchDevicon",
      { fg = icon_color, bg = vim.api.nvim_get_hl(0, { name = "BufSwitchDevicon" }).bg })
    local icon_hl = is_current and "BufSwitchDevicon" or "BufSwitchInactive"
    result = string.format("%%#%s#%s%%#%s# ", icon_hl, devicon, base_hl)
  end
  caches.devicon[cache_key] = { result = result, timestamp = get_timestamp() }
  return result
end

local function format_bufname(bufnr, is_current)
  local cache_key = bufnr .. ":" .. (is_current and "1" or "0")
  local cached = caches.bufname[cache_key]
  if cached and is_cache_valid(cached.timestamp) then
    return cached.result
  end
  local name = vim.api.nvim_buf_is_valid(bufnr) and vim.fn.bufname(bufnr) or ""
  if not name or name == "" then
    return "[Invalid]"
  end
  local buftype = vim.bo[bufnr].buftype
  local display_name = vim.fs.basename(name) or "[No Name]"
  if buftype == "help" then
    display_name = "[Help] " .. (display_name ~= "[No Name]" and display_name or "help")
  elseif buftype == "terminal" then
    display_name = "[Term] " .. (display_name ~= "[No Name]" and display_name:gsub("^term://.*//", "") or "terminal")
  elseif display_name == "[No Name]" then
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

local function render_tabline(buffer_order, cycle_index, cache_ref, ttl)
  local buffer_hash = hash_buffer_list(buffer_order, cycle_index)
  if cache_ref.buffer_hash == buffer_hash
    and is_cache_valid(cache_ref.timestamp, ttl or 100) then
    return cache_ref.content
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local total_buffers = #buffer_order
  local display_window = state.config.tabline_display_window

  if total_buffers == 0 then
    return "%#BufSwitchFill#%T"
  end

  local current_index = 0
  if cycle_index then
    current_index = cycle_index
  else
    for i, bufnr in ipairs(buffer_order) do
      if bufnr == current_buf then
        current_index = i
        break
      end
    end
    if current_index == 0 and total_buffers > 0 then
      current_index = 1
    end
  end

  local win_offset = math.max(1, math.min(
    current_index - math.floor(display_window / 2),
    total_buffers - display_window + 1
  ))

  local start_index = win_offset
  local end_index = math.min(start_index + display_window - 1, total_buffers)

  local parts = {}
  if start_index > 1 then
    table.insert(parts, "%#BufSwitchSeparator#<..")
  end

  for i = start_index, end_index do
    local bufnr = buffer_order[i]
    if vim.api.nvim_buf_is_valid(bufnr) then
      local is_current = (cycle_index and i == cycle_index) or bufnr == current_buf
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
  local tabline_content = table.concat({
    "%#BufSwitchFill#", table.concat(parts, ""), "%T"
  })

  -- Update cache
  cache_ref.content = tabline_content
  cache_ref.timestamp = get_timestamp()
  cache_ref.buffer_hash = buffer_hash

  return tabline_content
end

local M = {}

function M.update_tabline(buflist, cycle_index)
  vim.o.tabline = render_tabline(buflist, cycle_index, caches.tabline, 100)
end

local function update_tabline_debounced(buffer_list, cycle_index)
  if not timers.update then
    timers.update = vim.loop.new_timer()
  end
  timers.update:stop()
  timers.update:start(debounce_delay, 0, vim.schedule_wrap(function()
    M.update_tabline(buffer_list, cycle_index)
    timers.update:stop()
  end))
end

function M.show_tabline_temporarily(_, buffer_order)
  if state.config.hide_in_special and utils.is_special_buffer(state.config) then
    return
  end
  utils.stop_hide_timer()
  vim.o.showtabline = 2

  update_tabline_debounced(buffer_order, nil)

  utils.start_hide_timer(state.config.hide_timeout, function()
    vim.o.showtabline = 0
  end)
end

function M.show_tabline_static()
  if state.config.hide_in_special and utils.is_special_buffer(state.config) then
    return
  end
  utils.stop_hide_timer()
  vim.o.showtabline = 2

  vim.o.tabline = render_tabline(state.tabline_order, nil, caches.static_tabline, 100)

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
  local bufname_count = 0
  for _ in pairs(caches.bufname) do bufname_count = bufname_count + 1 end
  if bufname_count > 100 then
    for key, entry in pairs(caches.bufname) do
      if not is_cache_valid(entry.timestamp, cache_ttl) then
        caches.bufname[key] = nil
      end
    end
  end
  local devicon_count = 0
  for _ in pairs(caches.devicon) do devicon_count = devicon_count + 1 end
  if devicon_count > 100 then
    for key, entry in pairs(caches.devicon) do
      if not is_cache_valid(entry.timestamp, cache_ttl) then
        caches.devicon[key] = nil
      end
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
  caches.static_tabline.buffer_hash = ""
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
return M
