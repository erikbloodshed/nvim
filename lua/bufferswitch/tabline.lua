local utils = require("bufferswitch.utils")
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local config = {
  hide_in_special = true,
  hide_timeout = 2000,
  cache_ttl = 5000,
  debounce_delay = 16,
}

-- Caching infrastructure
local caches = {
  bufname = {},
  devicon = {},
  tabline = { content = "", timestamp = 0, buffer_hash = "" },
}

local timers = {
  update = nil,
  cache_cleanup = nil,
}

-- Utility functions
local function get_timestamp()
  return vim.loop.hrtime() / 1000000 -- Convert to milliseconds
end

local function is_cache_valid(timestamp, ttl)
  return get_timestamp() - timestamp < (ttl or config.cache_ttl)
end

local function hash_buffer_list(buffer_list)
  local current_buf = vim.api.nvim_get_current_buf()
  local parts = { tostring(current_buf) }

  for _, bufnr in ipairs(buffer_list) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local modified = vim.bo[bufnr].modified and "1" or "0"
      table.insert(parts, tostring(bufnr) .. ":" .. modified)
    end
  end

  return table.concat(parts, "|")
end

-- Cached devicon lookup
local function get_cached_devicon(display_name, filepath, is_current, base_hl)
  if not has_devicons then
    return ""
  end

  local basename = vim.fs.basename(filepath) or ""
  local ext = basename:match("%.([^%.]+)$") or ""
  local cache_key = display_name .. ":" .. ext .. ":" .. (is_current and "1" or "0")

  local cached = caches.devicon[cache_key]
  if cached and is_cache_valid(cached.timestamp) then
    return cached.result
  end

  local devicon, icon_color = devicons.get_icon_color(display_name, ext)
  local result = ""

  if devicon then
    local hl = vim.api.nvim_get_hl(0, { name = "PmenuSel" })
    vim.api.nvim_set_hl(0, "BufferSwitchDevicon", { fg = icon_color, bg = hl.bg })
    local icon_hl = is_current and "BufferSwitchDevicon" or "BufferSwitchInactive"
    result = string.format("%%#%s#%s%%#%s# ", icon_hl, devicon, base_hl)
  end

  caches.devicon[cache_key] = {
    result = result,
    timestamp = get_timestamp()
  }

  return result
end

local format_bufname = function(bufnr, is_current)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return "[Invalid]"
  end

  local modified = vim.bo[bufnr].modified
  local buftype = vim.bo[bufnr].buftype
  local cache_key = bufnr .. ":" .. (is_current and "1" or "0") .. ":" .. (modified and "1" or "0")

  local cached = caches.bufname[cache_key]
  if cached and is_cache_valid(cached.timestamp) then
    return cached.result
  end

  local name = vim.fn.bufname(bufnr)
  local display_name = vim.fn.fnamemodify(name, ":t")

  -- Handle special buffer types
  if buftype == "help" then
    display_name = "[Help] " .. (display_name ~= "" and display_name or "help")
  elseif buftype == "terminal" then
    display_name = "[Term] " .. (display_name ~= "" and display_name:gsub("^term://.*//", "") or "terminal")
  elseif display_name == "" then
    display_name = "[No Name]"
  end

  -- Truncate long names
  if #display_name > 25 then
    display_name = display_name:sub(1, 22) .. "..."
  end

  local base_hl = is_current and "BufferSwitchSelected" or "BufferSwitchInactive"

  -- Build result components
  local components = {}

  -- Add devicon
  local devicon = get_cached_devicon(vim.fn.fnamemodify(name, ":t"), name, is_current, base_hl)
  if devicon ~= "" then
    table.insert(components, devicon)
  end

  -- Add display name
  table.insert(components, display_name)

  -- Add modified marker
  if modified then
    table.insert(components, "%#BufferSwitchModified#●%#" .. base_hl .. "#")
  end

  local result = table.concat(components)

  caches.bufname[cache_key] = {
    result = result,
    timestamp = get_timestamp()
  }

  return result
end

local M = {}

function M.update_tabline(buffer_list)
  local buffer_hash = hash_buffer_list(buffer_list)
  if caches.tabline.buffer_hash == buffer_hash and
    is_cache_valid(caches.tabline.timestamp, 100) then -- Very short TTL for tabline
    vim.o.tabline = caches.tabline.content
    return
  end

  local current_buf = vim.api.nvim_get_current_buf()
  local parts = {}

  -- Build buffer list
  for i, bufnr in ipairs(buffer_list) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local is_current = bufnr == current_buf
      local hl = is_current and "%#BufferSwitchSelected#" or "%#BufferSwitchInactive#"
      local entry = table.concat({ hl, "  ", format_bufname(bufnr, is_current), "  " })

      table.insert(parts, entry)

      if i < #buffer_list then
        table.insert(parts, "%#BufferSwitchSeparator#|")
      else
        table.insert(parts, "%#BufferSwitchFill#")
      end
    end
  end

  local tabline_content = table.concat({ "%#BufferSwitchFill#", table.concat(parts, ""), "%T" })

  -- Cache the result
  caches.tabline.content = tabline_content
  caches.tabline.timestamp = get_timestamp()
  caches.tabline.buffer_hash = buffer_hash

  vim.o.tabline = tabline_content
end

-- Debounced update wrapper
local function update_tabline_debounced(buffer_list)
  if timers.update then
    timers.update:stop()
    timers.update:close()
  end

  timers.update = vim.defer_fn(function()
    M.update_tabline(buffer_list)
    timers.update = nil
  end, config.debounce_delay)
end

function M.show_tabline_temporarily(_, buffer_order)
  if config.hide_in_special and utils.is_special_buffer(config) then
    return
  end

  utils.stop_hide_timer()
  vim.o.showtabline = 2

  update_tabline_debounced(buffer_order)

  utils.start_hide_timer(config.hide_timeout, function()
    vim.o.showtabline = 0
  end)
end

function M.hide_tabline()
  vim.o.showtabline = 0
  utils.stop_hide_timer()

  -- Cancel pending updates
  if timers.update then
    timers.update:stop()
    timers.update:close()
    timers.update = nil
  end
end

-- Cache management
local function cleanup_expired_cache()
  -- Clean bufname cache
  for key, entry in pairs(caches.bufname) do
    if not is_cache_valid(entry.timestamp) then
      caches.bufname[key] = nil
    end
  end

  -- Clean devicon cache
  for key, entry in pairs(caches.devicon) do
    if not is_cache_valid(entry.timestamp) then
      caches.devicon[key] = nil
    end
  end
end

local function invalidate_buffer_cache(bufnr)
  -- Remove all cache entries for this buffer
  for key in pairs(caches.bufname) do
    if key:match("^" .. bufnr .. ":") then
      caches.bufname[key] = nil
    end
  end

  -- Invalidate tabline cache
  caches.tabline.buffer_hash = ""
end

-- Setup cache cleanup and invalidation
local function setup_cache_management()
  -- Periodic cache cleanup
  timers.cache_cleanup = vim.fn.timer_start(30000, cleanup_expired_cache, { ['repeat'] = -1 })

  -- Buffer change invalidation
  vim.api.nvim_create_autocmd({ "BufWritePost", "BufDelete", "BufModifiedSet" }, {
    callback = function(args)
      invalidate_buffer_cache(args.buf)
    end,
  })
end

-- Initialize performance monitoring (optional)
function M.get_cache_stats()
  local function count_nested_cache(cache)
    local count = 0
    for _, level1 in pairs(cache) do
      if type(level1) == "table" then
        for _, level2 in pairs(level1) do
          if type(level2) == "table" then
            for _ in pairs(level2) do
              count = count + 1
            end
          else
            count = count + 1
          end
        end
      else
        count = count + 1
      end
    end
    return count
  end

  local stats = {
    bufname = count_nested_cache(caches.bufname),
    devicon = count_nested_cache(caches.devicon),
    tabline_age = get_timestamp() - caches.tabline.timestamp,
  }
  return stats
end

function M.clear_all_caches()
  caches.bufname = {}
  caches.devicon = {}
  caches.tabline = { content = "", timestamp = 0, buffer_hash = "" }
end

-- Initialize the module
setup_cache_management()
return M
