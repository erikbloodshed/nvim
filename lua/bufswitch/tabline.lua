local utils = require("bufswitch.utils")
local state = require("bufswitch.state")
local api, fn = vim.api, vim.fn
local table_insert = table.insert
local table_concat = table.concat
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local CACHE_TTL = 5000
local DEBOUNCE_DELAY = 16
local TABLINE_TTL = 100
local MAX_CACHE_SIZE = 100
local MAX_NAME_LENGTH = 16

local function get_timestamp()
  return fn.reltimefloat(fn.reltime()) * 1000
end

local function is_cache_valid(entry, ttl)
  return entry and (get_timestamp() - entry.timestamp < (ttl or CACHE_TTL))
end

local function cleanup_cache_tbl(cache_tbl)
  local count = 0
  for _ in pairs(cache_tbl) do count = count + 1 end

  if count > MAX_CACHE_SIZE then
    for key, entry in pairs(cache_tbl) do
      if not is_cache_valid(entry) then
        cache_tbl[key] = nil
      end
    end
  end
end

local cache = {
  buffer_info = {},
  tabline = { content = "", timestamp = 0, hash = "", window_start = 1 },
  static_tabline = { content = "", timestamp = 0, hash = "", window_start = 1 }
}

local function invalidate_buffer_cache(bufnr)
  cache.buffer_info[bufnr] = nil
  cache.tabline.hash = ""
  cache.tabline.window_start = 1
  cache.static_tabline.hash = ""
  cache.static_tabline.window_start = 1
end

local function hash_buflist(buflist, cycle_idx)
  if not next(buflist) then return "" end
  local current_buf = api.nvim_get_current_buf()
  local buffer_ids = table_concat(buflist, "-")
  return string.format("%d:%s:%d", current_buf, buffer_ids, cycle_idx or 0)
end

local function create_cache_entry(result)
  return { result = result, timestamp = get_timestamp() }
end

local function get_or_compute_buffer_info(bufnr)
  local cached = cache.buffer_info[bufnr]
  if is_cache_valid(cached) then
    return cached.result
  end

  if not api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local name = fn.bufname(bufnr) or ""
  if name == "" and fn.getbufvar(bufnr, '&modified') == 0 then
    if api.nvim_buf_line_count(bufnr) <= 1 and #vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == 0 then
      return nil -- Skip empty, unnamed, unmodified buffers.
    end
  end

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

  local info = { display_name = display_name, devicon = nil, icon_color = nil }

  if has_devicons then
    local ext = fn.fnamemodify(name, ":e") or ""
    info.devicon, info.icon_color = devicons.get_icon_color(display_name, ext)
  end

  cache.buffer_info[bufnr] = create_cache_entry(info)
  return info
end

local function format_buffer_from_info(info, is_current)
  if not info then return "[Invalid]" end

  local parts = {}
  if info.devicon then
    api.nvim_set_hl(0, "BufSwitchDevicon", {
      fg = info.icon_color,
      bg = api.nvim_get_hl(0, { name = "BufSwitchSelected", link = false }).bg
    })
    local base_hl = is_current and "BufSwitchSelected" or "BufSwitchInactive"
    local icon_hl = is_current and "BufSwitchDevicon" or "BufSwitchInactive"
    table_insert(parts, string.format("%%#%s#%s%%#%s# ", icon_hl, info.devicon, base_hl))
  end
  table_insert(parts, info.display_name)
  return table_concat(parts)
end

local function calculate_window_bounds(current_index, total_buffers, display_win, cache_ref)
  if total_buffers <= display_win then
    return 1, total_buffers
  end

  local window_start = cache_ref.window_start or 1
  local window_end = window_start + display_win - 1

  if current_index > window_end then
    window_start = current_index - display_win + 1
  elseif current_index < window_start then
    window_start = current_index
  end

  window_start = math.max(1, math.min(window_start, total_buffers - display_win + 1))
  local window_end_final = math.min(window_start + display_win - 1, total_buffers)

  cache_ref.window_start = window_start

  return window_start, window_end_final
end

local function find_current_index(buf_order, current_buf, cycle_idx)
  if cycle_idx then
    return cycle_idx
  end

  for i, bufnr in ipairs(buf_order) do
    if bufnr == current_buf then
      return i
    end
  end

  return #buf_order > 0 and 1 or 0
end

local config = state.config

local function render_tabline(buf_order, cycle_idx, cache_ref, ttl)
  local buffer_hash = hash_buflist(buf_order, cycle_idx)

  if cache_ref.hash == buffer_hash and is_cache_valid(cache_ref, ttl) then
    return cache_ref.content
  end

  local total_buffers = #buf_order
  if total_buffers == 0 then
    return "%#BufSwitchFill#%T"
  end

  local current_buf = api.nvim_get_current_buf()
  local current_index = find_current_index(buf_order, current_buf, cycle_idx)
  local display_win = config.tabline_display_window
  local start_index, end_index = calculate_window_bounds(current_index, total_buffers, display_win, cache_ref)

  local parts = { "%#BufSwitchFill#" }

  if start_index > 1 then
    table_insert(parts, "%#BufSwitchSeparator#<.. ")
  end

  for i = start_index, end_index do
    local bufnr = buf_order[i]
    if api.nvim_buf_is_valid(bufnr) then
      local info = get_or_compute_buffer_info(bufnr)
      if info then
        local is_current = (cycle_idx and i == cycle_idx) or bufnr == current_buf
        local hl = is_current and "%#BufSwitchSelected#" or "%#BufSwitchInactive#"

        if i > start_index or (i == start_index and start_index > 1) then
          table_insert(parts, "%#BufSwitchSeparator#|")
        end

        local formatted_string = format_buffer_from_info(info, is_current)
        table_insert(parts, hl .. "  " .. formatted_string .. "  ")
      end
    end
  end

  if end_index < total_buffers then
    table_insert(parts, "%#BufSwitchSeparator#| ..>")
  end

  table_insert(parts, "%#BufSwitchFill#%T")
  local tabline_content = table_concat(parts, "")

  cache_ref.content = tabline_content
  cache_ref.timestamp = get_timestamp()
  cache_ref.hash = buffer_hash

  return tabline_content
end

local M = {}

function M.update_tabline(buflist, cycle_idx)
  vim.o.tabline = render_tabline(buflist, cycle_idx, cache.tabline, TABLINE_TTL)
end

local update_timer = nil

local function show_with_hide_timer(callback)
  if config.hide_in_special and utils.is_special_buffer(config) then
    return
  end

  utils.stop_hide_timer()
  vim.o.showtabline = 2
  callback()

  utils.start_hide_timer(config.hide_timeout, function()
    vim.o.showtabline = 0
  end)
end

local function update_tabline_debounced(buflist, cycle_idx)
  if not update_timer then
    update_timer = vim.uv.new_timer()
  end

  if update_timer then
    update_timer:stop()
    update_timer:start(DEBOUNCE_DELAY, 0, vim.schedule_wrap(function()
      M.update_tabline(buflist, cycle_idx)
      if update_timer then
        update_timer:stop()
      end
    end))
  end
end

function M.show_tabline_temporarily(_, buf_order)
  show_with_hide_timer(function()
    update_tabline_debounced(buf_order, nil)
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

local function cleanup_expired_cache()
  cleanup_cache_tbl(cache.buffer_info)
end

fn.timer_start(30000, cleanup_expired_cache, { ['repeat'] = -1 })

api.nvim_create_autocmd({ "BufWritePost", "BufDelete", "BufModifiedSet" }, {
  callback = function(args)
    invalidate_buffer_cache(args.buf)
  end,
})

return M
