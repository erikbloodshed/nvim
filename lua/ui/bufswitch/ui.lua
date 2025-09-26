local api, fn = vim.api, vim.fn
local insert, concat = table.insert, table.concat
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local config = require("ui.bufswitch.config").config

local M = {}

local cache_ttl, debounce_delay, tabline_ttl = 5000, 16, 100
local max_cache_size, max_name_length = 100, 16
local cache = {
  bufinfo = {},
  tabline = { content = "", timestamp = 0, hash = "", window_start = 1 },
  static_tabline = { content = "", timestamp = 0, hash = "", window_start = 1 },
}

local hide_timer, update_timer
local function now() return fn.reltimefloat(fn.reltime()) * 1000 end
local function is_fresh(entry, ttl) return entry and (now() - (entry.timestamp or 0) < (ttl or cache_ttl)) end
local function cache_entry(result) return { result = result, timestamp = now() } end
local function reset_cache(tbl) tbl.content, tbl.timestamp, tbl.hash, tbl.window_start = "", 0, "", 1 end
local function cleanup_cache()
  local count = 0; for _ in pairs(cache.bufinfo) do count = count + 1 end
  if count > max_cache_size then for k, e in pairs(cache.bufinfo) do if not is_fresh(e) then cache.bufinfo[k] = nil end end end
end

function M.invalidate(buf)
  cache.bufinfo[buf] = nil
  reset_cache(cache.tabline); reset_cache(cache.static_tabline)
end

-- Buffer Info & Formatting -----------------------------------------------
local function get_info(buf)
  local c = cache.bufinfo[buf]; if is_fresh(c) then return c.result end
  local name, bt = fn.bufname(buf) or "", vim.bo[buf].buftype
  local disp = vim.fs.basename(name) or "[No Name]"
  if bt == "help" then
    disp = "[Help] " .. (disp ~= "[No Name]" and disp or "help")
  elseif bt == "terminal" then
    disp = "[Term] " .. (disp ~= "[No Name]" and disp:gsub("^term://.*//", "") or "terminal")
  end
  if #disp > max_name_length then disp = disp:sub(1, max_name_length - 3) .. "..." end

  local info = { display_name = disp }
  if has_devicons then info.devicon, info.icon_color = devicons.get_icon_color(disp, fn.fnamemodify(name, ":e") or "") end
  cache.bufinfo[buf] = cache_entry(info)
  return info
end

local function fmt(info, is_current)
  if not info then return "[Invalid]" end
  local parts = {}
  if info.devicon then
    api.nvim_set_hl(0, "BufSwitchDevicon", { fg = info.icon_color, bg = api.nvim_get_hl(0, { name = "BufSwitchSelected", link = false }).bg })
    insert(parts, string.format("%%#%s#%s%%#%s# ", is_current and "BufSwitchDevicon" or "BufSwitchInactive", info.devicon, is_current and "BufSwitchSelected" or "BufSwitchInactive"))
  end
  insert(parts, info.display_name)
  return concat(parts)
end

-- Tabline Rendering -------------------------------------------------------
local function hash(list, idx)
  if not next(list) then return "" end
  return string.format("%d:%s:%d", api.nvim_get_current_buf(), concat(list, "-"), idx or 0)
end

local function bounds(cur, total, win, ref)
  if total <= win then return 1, total end
  local s = ref.window_start or 1
  if cur > s + win - 1 then s = cur - win + 1 elseif cur < s then s = cur end
  s = math.max(1, math.min(s, total - win + 1)); ref.window_start = s
  return s, math.min(s + win - 1, total)
end

local function idx(order, cur, cyc)
  if cyc and cyc > 0 then return cyc end
  for i, b in ipairs(order) do if b == cur then return i end end
  return #order > 0 and 1 or 0
end

local function render(order, cyc_idx, ref, ttl)
  local h = hash(order, cyc_idx)
  if ref.hash == h and is_fresh(ref, ttl) then return ref.content end
  local total = #order; if total == 0 then return "%#BufSwitchFill#%T" end

  local cur_buf = api.nvim_get_current_buf()
  local cur_idx = idx(order, cur_buf, cyc_idx)
  local s, e = bounds(cur_idx, total, config.tabline_display_window, ref)

  local parts = { "%#BufSwitchFill#" }
  if s > 1 then insert(parts, "%#BufSwitchSeparator#<.. ") end
  for i = s, e do
    local b = order[i]
    if api.nvim_buf_is_valid(b) then
      local info, curflag = get_info(b), (cyc_idx and i == cyc_idx) or b == cur_buf
      if info then
        if i > s then insert(parts, "%#BufSwitchSeparator#|") end
        insert(parts, (curflag and "%#BufSwitchSelected#" or "%#BufSwitchInactive#") .. "  " .. fmt(info, curflag) .. "  ")
      end
    end
  end
  if e < total then insert(parts, "%#BufSwitchSeparator#| ..>") end
  insert(parts, "%#BufSwitchFill#%T")

  local out = concat(parts, "")
  ref.content, ref.timestamp, ref.hash = out, now(), h
  return out
end

local function stop_timer(t)
  if t and not t:is_closing() then t:stop(); t:close() end
  return nil
end

function M.start_timer(timeout, cb)
  hide_timer = stop_timer(hide_timer)
  hide_timer = vim.uv.new_timer()
  if hide_timer then hide_timer:start(timeout, 0, vim.schedule_wrap(cb)) end
end

function M.stop_timer() hide_timer = stop_timer(hide_timer) end

local function show(cb)
  M.stop_timer()
  vim.o.showtabline = 2
  cb()
  M.start_timer(config.hide_timeout, function() vim.o.showtabline = 0 end)
end

function M.update(order, cyc_idx) vim.o.tabline = render(order, cyc_idx, cache.tabline, tabline_ttl) end

function M.update_debounced(order)
  update_timer = update_timer or vim.uv.new_timer()
  if update_timer then
    update_timer:stop()
    update_timer:start(debounce_delay, 0, vim.schedule_wrap(function()
      M.update(order); update_timer:stop()
    end))
  end
end

function M.show_temp(order) show(function() M.update_debounced(order) end) end

function M.show_static(order)
  show(function()
    vim.o.tabline = render(order, nil, cache.static_tabline, tabline_ttl)
  end)
end

function M.init()
  if config.periodic_cleanup then
    fn.timer_start(30000, function() cleanup_cache() end, { ['repeat'] = -1 })
  end
end

return M
