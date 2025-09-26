local api, fn = vim.api, vim.fn
local insert, remove, concat = table.insert, table.remove, table.concat
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local M = {}

-- Configuration ---------------------------------------------------------
local config = {
  hide_timeout = 1000,
  show_tabline = true,
  hide_in_special = true,
  disable_in_special = true,
  periodic_cleanup = true,
  debug = false,
  tabline_display_window = 8,
  wrap_around = true,
  special_buftypes = { "quickfix", "help", "nofile", "prompt" },
  special_filetypes = { "qf", "help", "netrw", "neo-tree", "NvimTree", "terminal" },
  special_bufname_patterns = { "^term://", "^neo%-tree " },
}

-- State -----------------------------------------------------------------
local state = {
  buf_order = {},
  tabline_order = {},
  cycle = { active = false, index = 0 },
}

-- Cache -----------------------------------------------------------------
local cache_ttl, debounce_delay, tabline_ttl = 5000, 16, 100
local max_cache_size, max_name_length = 100, 16
local cache = {
  bufinfo = {},
  tabline = { content = "", timestamp = 0, hash = "", window_start = 1 },
  static_tabline = { content = "", timestamp = 0, hash = "", window_start = 1 },
}

-- Timers ----------------------------------------------------------------
local hide_timer, update_timer

-- Utility ---------------------------------------------------------------
local function now() return fn.reltimefloat(fn.reltime()) * 1000 end
local function is_fresh(entry, ttl) return entry and (now() - (entry.timestamp or 0) < (ttl or cache_ttl)) end
local function cache_entry(result) return { result = result, timestamp = now() } end
local function remove_item(tbl, val)
  for i, x in ipairs(tbl) do
    if x == val then
      remove(tbl, i)
      return
    end
  end
end
local function reset_cache(tbl) tbl.content, tbl.timestamp, tbl.hash, tbl.window_start = "", 0, "", 1 end
local function scheduled(cb) return function(ev) vim.schedule(function() cb(ev) end) end end

local function is_empty_unnamed(buf)
  if not api.nvim_buf_is_valid(buf) or fn.bufname(buf) ~= "" or fn.getbufvar(buf, '&modified') ~= 0 then return false end
  local lc = api.nvim_buf_line_count(buf)
  return (lc > 1) or (lc == 1 and #(api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "") > 0)
end

local function skip_unnamed(buf)
  return fn.bufname(buf) == "" and fn.getbufvar(buf, "&modified") == 0 and not is_empty_unnamed(buf)
end

local function is_special(buf)
  buf = buf or api.nvim_get_current_buf()
  if vim.tbl_contains(config.special_buftypes, vim.bo[buf].buftype)
    or vim.tbl_contains(config.special_filetypes, vim.bo[buf].filetype) then
    return true
  end
  for _, pat in ipairs(config.special_bufname_patterns) do if fn.bufname(buf):match(pat) then return true end end
  return fn.win_gettype() ~= ""
end

-- Cache ops -------------------------------------------------------------
local function cleanup(tbl)
  local count = 0; for _ in pairs(tbl) do count = count + 1 end
  if count > max_cache_size then for k, e in pairs(tbl) do if not is_fresh(e) then tbl[k] = nil end end end
end

local function invalidate(buf)
  cache.bufinfo[buf] = nil
  reset_cache(cache.tabline); reset_cache(cache.static_tabline)
end

-- Buffer info -----------------------------------------------------------
local function get_info(buf)
  local c = cache.bufinfo[buf]; if is_fresh(c) then return c.result end
  if not api.nvim_buf_is_valid(buf) or skip_unnamed(buf) then return nil end

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
    api.nvim_set_hl(0, "BufSwitchDevicon",
      { fg = info.icon_color, bg = api.nvim_get_hl(0, { name = "BufSwitchSelected", link = false }).bg })
    insert(parts,
      string.format("%%#%s#%s%%#%s# ", is_current and "BufSwitchDevicon" or "BufSwitchInactive", info.devicon,
        is_current and "BufSwitchSelected" or "BufSwitchInactive"))
  end
  insert(parts, info.display_name)
  return concat(parts)
end

-- Tabline ---------------------------------------------------------------
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

local function render(order, cyc, ref, ttl)
  local h = hash(order, cyc)
  if ref.hash == h and is_fresh(ref, ttl) then return ref.content end
  local total = #order; if total == 0 then return "%#BufSwitchFill#%T" end

  local cur, cur_idx = api.nvim_get_current_buf(), idx(order, api.nvim_get_current_buf(), cyc)
  local s, e = bounds(cur_idx, total, config.tabline_display_window, ref)

  local parts = { "%#BufSwitchFill#" }
  if s > 1 then insert(parts, "%#BufSwitchSeparator#<.. ") end
  for i = s, e do
    local b = order[i]
    if api.nvim_buf_is_valid(b) then
      local info, curflag = get_info(b), (cyc and i == cyc) or b == cur
      if info then
        if i > s then insert(parts, "%#BufSwitchSeparator#|") end
        insert(parts,
          (curflag and "%#BufSwitchSelected#" or "%#BufSwitchInactive#") .. "  " .. fmt(info, curflag) .. "  ")
      end
    end
  end
  if e < total then insert(parts, "%#BufSwitchSeparator#| ..>") end
  insert(parts, "%#BufSwitchFill#%T")

  local out = concat(parts, "")
  ref.content, ref.timestamp, ref.hash = out, now(), h
  return out
end

local function update(order, cyc) vim.o.tabline = render(order, cyc, cache.tabline, tabline_ttl) end

-- Show/hide helpers -----------------------------------------------------
local function stop_timer(t)
  if t and not t:is_closing() then
    t:stop(); t:close()
  end
  return nil
end
local function start_timer(timeout, cb)
  hide_timer = stop_timer(hide_timer)
  hide_timer = vim.uv.new_timer()
  if hide_timer then hide_timer:start(timeout, 0, vim.schedule_wrap(cb)) end
end

local function show(cb)
  if config.hide_in_special and is_special() then return end
  hide_timer = stop_timer(hide_timer)
  vim.o.showtabline = 2
  cb()
  start_timer(config.hide_timeout, function() vim.o.showtabline = 0 end)
end

local function update_debounced(order, cyc)
  update_timer = update_timer or vim.uv.new_timer()
  if update_timer then
    update_timer:stop()
    update_timer:start(debounce_delay, 0, vim.schedule_wrap(function()
      update(order, cyc); update_timer:stop()
    end))
  end
end

local function show_temp(_, order) show(function() update_debounced(order) end) end
local function show_static()
  show(function()
    vim.o.tabline = render(state.tabline_order, nil, cache.static_tabline,
      tabline_ttl)
  end)
end

-- Periodic cleanup ------------------------------------------------------
if config.periodic_cleanup then fn.timer_start(30000, function() cleanup(cache.bufinfo) end, { ['repeat'] = -1 }) end

-- Buffer management -----------------------------------------------------
local function include(buf)
  return api.nvim_buf_is_valid(buf) and fn.buflisted(buf) == 1 and not is_special(buf) and
    not skip_unnamed(buf)
end
local function update_mru(buf)
  if include(buf) then
    remove_item(state.buf_order, buf); insert(state.buf_order, buf)
  end
end
local function remove_buf(buf)
  remove_item(state.buf_order, buf); remove_item(state.tabline_order, buf); invalidate(buf)
end

-- Cycle -----------------------------------------------------------------
local function end_cycle()
  if not state.cycle.active then return end
  hide_timer = stop_timer(hide_timer)
  vim.o.showtabline = 0
  local f = state.tabline_order[state.cycle.index]
  state.cycle.active, state.cycle.index = false, 0
  if f and api.nvim_buf_is_valid(f) then update_mru(f) end
  if config.show_tabline then update(state.tabline_order) end
end

local function navigate(move)
  if config.disable_in_special and is_special() then return end
  hide_timer = stop_timer(hide_timer)

  if not state.cycle.active then
    if #state.tabline_order < 2 then
      show_temp(nil, state.tabline_order)
      return
    end
    state.cycle.active, state.cycle.index = true, 0
    for i, b in ipairs(state.tabline_order) do
      if b == api.nvim_get_current_buf() then
        state.cycle.index = i
        break
      end
    end
    if state.cycle.index == 0 then state.cycle.index = 1 end
  end

  if move == "recent" then
    local n = #state.buf_order; if n < 2 then return end
    local target = (api.nvim_get_current_buf() == state.buf_order[n]) and state.buf_order[n - 1] or state.buf_order[n]
    for i, b in ipairs(state.tabline_order) do
      if b == target then
        state.cycle.index = i
        break
      end
    end
    if state.cycle.index == 0 then return end
  else
    local step = (move == "prev") and -1 or 1
    state.cycle.index = state.cycle.index + step
    if state.cycle.index < 1 then
      if not config.wrap_around then
        show_temp(nil, state.tabline_order)
        return
      end; state.cycle.index = #state.tabline_order
    elseif state.cycle.index > #state.tabline_order then
      if not config.wrap_around then
        show_temp(nil, state.tabline_order)
        return
      end; state.cycle.index = 1
    end
  end

  local t = state.tabline_order[state.cycle.index]
  if not (t and api.nvim_buf_is_valid(t)) then
    end_cycle()
    return
  end
  vim.cmd('buffer ' .. t)
  vim.o.showtabline = 2
  update(state.tabline_order, state.cycle.index)
  start_timer(config.hide_timeout, end_cycle)
end

-- Setup -----------------------------------------------------------------
local function setup_autocmds()
  local ag = api.nvim_create_augroup('BufferSwitcher', { clear = true })
  api.nvim_create_autocmd('BufEnter',
    {
      group = ag,
      callback = scheduled(function()
        if not state.cycle.active then
          update_mru(api.nvim_get_current_buf()); if config.show_tabline then update(state.tabline_order) end
        end
      end)
    })
  api.nvim_create_autocmd('BufAdd',
    {
      group = ag,
      callback = scheduled(function(ev)
        if not state.cycle.active and include(ev.buf) then
          insert(state.tabline_order, ev.buf); update_mru(ev.buf)
        end
      end)
    })
  api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, { group = ag, callback = function(ev) remove_buf(ev.buf) end })
  api.nvim_create_autocmd({ 'BufWritePost', 'BufModifiedSet' },
    { group = ag, callback = function(ev) invalidate(ev.buf) end })
end

for _, b in ipairs(api.nvim_list_bufs()) do
  if include(b) then
    insert(state.buf_order, b); insert(state.tabline_order, b)
  end
end
update_mru(api.nvim_get_current_buf())
setup_autocmds()

local map, opts = vim.keymap.set, { noremap = true, nowait = true, silent = true }
map({ 'n', 'i' }, "<Right>", function() navigate("next") end, opts)
map({ 'n', 'i' }, "<Left>", function() navigate("prev") end, opts)
map({ 'n', 'i' }, "<Up>", function() navigate("recent") end, opts)
map({ 'n', 'i' }, "<Down>", show_static, opts)

return M
