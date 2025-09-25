local api, fn = vim.api, vim.fn
local tbl_insert, tbl_remove, tbl_concat = table.insert, table.remove, table.concat
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local M = {}

local default_config = {
  hide_timeout = 800,
  show_tabline = true,
  hide_in_special = true,
  disable_in_special = true,
  periodic_cleanup = true,
  debug = false,
  tabline_display_window = 15,
  wrap_around = false,
  special_buftypes = { "quickfix", "help", "nofile", "prompt" },
  special_filetypes = { "qf", "help", "netrw", "neo-tree", "NvimTree", "terminal" },
  special_bufname_patterns = { "^term://", "^neo%-tree " },
}

local user_config = {
  hide_timeout = 1000,
  tabline_display_window = 8,
  wrap_around = true,
  debug = false,
}

local config = vim.tbl_deep_extend("force", default_config, user_config or {})

local state = {
  buf_order = {},
  tabline_order = {},
  cycle = { active = false, index = 0 },
}

local cache_ttle = 5000
local debounce_delay = 16
local tabline_ttl = 100
local max_cache_size = 100
local max_name_length = 16

local cache = {
  bufinfo = {},
  tabline = { content = "", timestamp = 0, hash = "", window_start = 1 },
  static_tabline = { content = "", timestamp = 0, hash = "", window_start = 1 },
}

local hide_timer
local update_timer

local function now_ms()
  return fn.reltimefloat(fn.reltime()) * 1000
end

local function is_cache_valid(entry, ttl)
  return entry and (now_ms() - (entry.timestamp or 0) < (ttl or cache_ttle))
end

local function create_cache_entry(result)
  return { result = result, timestamp = now_ms() }
end

local function remove_from(tbl, val)
  for i, v in ipairs(tbl) do
    if v == val then
      tbl_remove(tbl, i)
      return
    end
  end
end

local function is_empty_unnamed(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then return false end
  if fn.bufname(bufnr) ~= "" then return false end
  if fn.getbufvar(bufnr, '&modified') ~= 0 then return false end
  local line_count = api.nvim_buf_line_count(bufnr)
  if line_count > 1 then return true end
  if line_count == 1 then
    local line = api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
    return #line > 0
  end
  return false
end

local function reset_tabline_cache(tbl)
  tbl.content = ""
  tbl.timestamp = 0
  tbl.hash = ""
  tbl.window_start = 1
end

local function is_special_buf(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local btype = vim.bo[bufnr].buftype
  local ftype = vim.bo[bufnr].filetype
  local name = fn.bufname(bufnr)

  if vim.tbl_contains(config.special_buftypes, btype) or vim.tbl_contains(config.special_filetypes, ftype) then
    return true
  end
  for _, pat in ipairs(config.special_bufname_patterns) do
    if name:match(pat) then return true end
  end
  return fn.win_gettype() ~= ""
end

local function cleanup_cache_tbl(cache_tbl)
  local count = 0
  for _ in pairs(cache_tbl) do count = count + 1 end
  if count > max_cache_size then
    for k, entry in pairs(cache_tbl) do
      if not is_cache_valid(entry) then cache_tbl[k] = nil end
    end
  end
end

local function invalidate_bufcache(bufnr)
  cache.bufinfo[bufnr] = nil
  reset_tabline_cache(cache.tabline)
  reset_tabline_cache(cache.static_tabline)
end

local function get_bufinfo(bufnr)
  local cached = cache.bufinfo[bufnr]
  if is_cache_valid(cached) then return cached.result end
  if not api.nvim_buf_is_valid(bufnr) then return nil end

  if is_empty_unnamed(bufnr) == false and fn.bufname(bufnr) == "" and fn.getbufvar(bufnr, '&modified') == 0 then
    return nil
  end

  local name = fn.bufname(bufnr) or ""
  local display_name = vim.fs.basename(name) or "[No Name]"
  local buftype = vim.bo[bufnr].buftype

  if buftype == "help" then
    display_name = "[Help] " .. (display_name ~= "[No Name]" and display_name or "help")
  elseif buftype == "terminal" then
    display_name = "[Term] " .. (display_name ~= "[No Name]" and display_name:gsub("^term://.*//", "") or "terminal")
  end

  if #display_name > max_name_length then
    display_name = display_name:sub(1, max_name_length - 3) .. "..."
  end

  local info = { display_name = display_name, devicon = nil, icon_color = nil }
  if has_devicons then
    local ext = fn.fnamemodify(name, ":e") or ""
    info.devicon, info.icon_color = devicons.get_icon_color(display_name, ext)
  end

  cache.bufinfo[bufnr] = create_cache_entry(info)
  return info
end

local function format_buf(info, is_current)
  if not info then return "[Invalid]" end
  local parts = {}
  if info.devicon then
    api.nvim_set_hl(0, "BufSwitchDevicon", {
      fg = info.icon_color,
      bg = api.nvim_get_hl(0, { name = "BufSwitchSelected", link = false }).bg,
    })
    local base_hl = is_current and "BufSwitchSelected" or "BufSwitchInactive"
    local icon_hl = is_current and "BufSwitchDevicon" or "BufSwitchInactive"
    tbl_insert(parts, string.format("%%#%s#%s%%#%s# ", icon_hl, info.devicon, base_hl))
  end
  tbl_insert(parts, info.display_name)
  return tbl_concat(parts)
end

local function hash_buflist(buflist, cycle_idx)
  if not next(buflist) then return "" end
  local current_buf = api.nvim_get_current_buf()
  local buffer_ids = tbl_concat(buflist, "-")
  return string.format("%d:%s:%d", current_buf, buffer_ids, cycle_idx or 0)
end

local function calc_win_bounds(current_idx, total_bufs, display_win, cache_ref)
  if total_bufs <= display_win then return 1, total_bufs end
  local ws = cache_ref.window_start or 1
  local we = ws + display_win - 1
  if current_idx > we then
    ws = current_idx - display_win + 1
  elseif current_idx < ws then
    ws = current_idx
  end
  ws = math.max(1, math.min(ws, total_bufs - display_win + 1))
  cache_ref.window_start = ws
  return ws, math.min(ws + display_win - 1, total_bufs)
end

local function find_current_idx(buf_order, current_buf, cycle_idx)
  if cycle_idx and cycle_idx > 0 then return cycle_idx end
  for i, b in ipairs(buf_order) do if b == current_buf then return i end end
  return #buf_order > 0 and 1 or 0
end

local function render_tabline(buf_order, cycle_idx, cache_ref, ttl)
  local buffer_hash = hash_buflist(buf_order, cycle_idx)
  if cache_ref.hash == buffer_hash and is_cache_valid(cache_ref, ttl) then
    return cache_ref.content
  end

  local total_buffers = #buf_order
  if total_buffers == 0 then return "%#BufSwitchFill#%T" end

  local current_buf = api.nvim_get_current_buf()
  local current_idx = find_current_idx(buf_order, current_buf, cycle_idx)
  local start_idx, end_idx = calc_win_bounds(current_idx, total_buffers, config.tabline_display_window, cache_ref)

  local parts = { "%#BufSwitchFill#" }
  if start_idx > 1 then tbl_insert(parts, "%#BufSwitchSeparator#<.. ") end

  for i = start_idx, end_idx do
    local bufnr = buf_order[i]
    if api.nvim_buf_is_valid(bufnr) then
      local info = get_bufinfo(bufnr)
      if info then
        local is_current = (cycle_idx and i == cycle_idx) or bufnr == current_buf
        if i > start_idx or (i == start_idx and start_idx > 1) then tbl_insert(parts, "%#BufSwitchSeparator#|") end
        tbl_insert(parts,
          (is_current and "%#BufSwitchSelected#" or "%#BufSwitchInactive#") ..
          "  " .. format_buf(info, is_current) .. "  ")
      end
    end
  end

  if end_idx < total_buffers then tbl_insert(parts, "%#BufSwitchSeparator#| ..>") end
  tbl_insert(parts, "%#BufSwitchFill#%T")

  local tabline_content = tbl_concat(parts, "")
  cache_ref.content = tabline_content
  cache_ref.timestamp = now_ms()
  cache_ref.hash = buffer_hash
  return tabline_content
end

local function tabline_update_tabline(buflist, cycle_idx)
  vim.o.tabline = render_tabline(buflist, cycle_idx, cache.tabline, tabline_ttl)
end

local function stop_hide_timer()
  if hide_timer and not hide_timer:is_closing() then
    hide_timer:stop(); hide_timer:close(); hide_timer = nil
  end
end

local function start_hide_timer(timeout, callback)
  stop_hide_timer()
  hide_timer = vim.uv.new_timer()
  if hide_timer then hide_timer:start(timeout, 0, vim.schedule_wrap(callback)) end
end

local function show_with_hide_timer(callback)
  if config.hide_in_special and is_special_buf() then return end
  stop_hide_timer()
  vim.o.showtabline = 2
  callback()
  start_hide_timer(config.hide_timeout, function() vim.o.showtabline = 0 end)
end

local function tabline_update_tabline_debounced(buflist, cycle_idx)
  if not update_timer then update_timer = vim.uv.new_timer() end
  if update_timer then
    update_timer:stop()
    update_timer:start(debounce_delay, 0, vim.schedule_wrap(function()
      tabline_update_tabline(buflist, cycle_idx)
      if update_timer then update_timer:stop() end
    end))
  end
end

local function tabline_show_temp_tabline(_, buf_order)
  show_with_hide_timer(function() tabline_update_tabline_debounced(buf_order, nil) end)
end

local function tabline_show_static_tabline()
  show_with_hide_timer(function()
    vim.o.tabline = render_tabline(state.tabline_order, nil, cache.static_tabline, tabline_ttl)
  end)
end

if config.periodic_cleanup then
  fn.timer_start(30000, function() cleanup_cache_tbl(cache.bufinfo) end, { ['repeat'] = -1 })
end

api.nvim_create_autocmd({ "BufWritePost", "BufDelete", "BufModifiedSet" }, {
  callback = function(args) invalidate_bufcache(args.buf) end,
})

local function include_buf(bufnr)
  if not api.nvim_buf_is_valid(bufnr) or fn.buflisted(bufnr) ~= 1 then return false end
  if is_special_buf(bufnr) then return false end
  if fn.bufname(bufnr) == "" and fn.getbufvar(bufnr, '&modified') == 0 then
    return is_empty_unnamed(bufnr)
  end
  return true
end

local function update_buffer_mru(bufnr)
  if not include_buf(bufnr) then return end
  remove_from(state.buf_order, bufnr)
  tbl_insert(state.buf_order, bufnr)
end

local function remove_buf(bufnr)
  remove_from(state.buf_order, bufnr)
  remove_from(state.tabline_order, bufnr)
  invalidate_bufcache(bufnr)
end

local function end_cycle()
  if not state.cycle.active then return end
  stop_hide_timer()
  vim.o.showtabline = 0
  local final_bufnr = state.tabline_order[state.cycle.index]
  state.cycle.active = false; state.cycle.index = 0
  if final_bufnr and api.nvim_buf_is_valid(final_bufnr) then update_buffer_mru(final_bufnr) end
  if config.show_tabline then tabline_update_tabline(state.tabline_order) end
end

local function core_navigate(move)
  if config.disable_in_special and is_special_buf() then return end
  stop_hide_timer()

  if not state.cycle.active then
    if #state.tabline_order < 2 then
      tabline_show_temp_tabline(nil, state.tabline_order); return
    end
    state.cycle.active = true; state.cycle.index = 0
    local current_buf = api.nvim_get_current_buf()
    for i, b in ipairs(state.tabline_order) do if b == current_buf then
        state.cycle.index = i; break
      end end
    if state.cycle.index == 0 then state.cycle.index = 1 end
  end

  if move == "recent" then
    local mru_size = #state.buf_order
    if mru_size < 2 then return end
    local target = (api.nvim_get_current_buf() == state.buf_order[mru_size]) and state.buf_order[mru_size - 1] or
    state.buf_order[mru_size]
    state.cycle.index = 0
    for i, b in ipairs(state.tabline_order) do if b == target then
        state.cycle.index = i; break
      end end
    if state.cycle.index == 0 then return end
  else
    local step = (move == "prev") and -1 or 1
    state.cycle.index = state.cycle.index + step
    if state.cycle.index < 1 then
      if not config.wrap_around then
        tabline_show_temp_tabline(nil, state.tabline_order); return
      end
      state.cycle.index = #state.tabline_order
    elseif state.cycle.index > #state.tabline_order then
      if not config.wrap_around then
        tabline_show_temp_tabline(nil, state.tabline_order); return
      end
      state.cycle.index = 1
    end
  end

  local target_bufnr = state.tabline_order[state.cycle.index]
  if not (target_bufnr and api.nvim_buf_is_valid(target_bufnr)) then
    end_cycle(); return
  end
  vim.cmd('buffer ' .. target_bufnr)
  vim.o.showtabline = 2
  tabline_update_tabline(state.tabline_order, state.cycle.index)
  start_hide_timer(config.hide_timeout, end_cycle)
end

local function setup_autocmds()
  local ag = api.nvim_create_augroup('BufferSwitcher', { clear = true })
  api.nvim_create_autocmd('BufEnter', {
    group = ag,
    callback = function()
      vim.schedule(function()
        if state.cycle.active then return end
        update_buffer_mru(api.nvim_get_current_buf())
        if config.show_tabline then tabline_update_tabline(state.tabline_order) end
      end)
    end,
  })
  api.nvim_create_autocmd('BufAdd', {
    group = ag,
    callback = function(ev)
      vim.schedule(function()
        if state.cycle.active then return end
        if include_buf(ev.buf) then
          tbl_insert(state.tabline_order, ev.buf); update_buffer_mru(ev.buf)
        end
      end)
    end,
  })
  api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = ag,
    callback = function(ev) remove_buf(ev.buf) end,
  })
end

state.buf_order = {}
state.tabline_order = {}
for _, bufnr in ipairs(api.nvim_list_bufs()) do if include_buf(bufnr) then
    tbl_insert(state.buf_order, bufnr); tbl_insert(state.tabline_order, bufnr)
  end end
update_buffer_mru(api.nvim_get_current_buf())
setup_autocmds()

local keyset = vim.keymap.set
keyset({ 'n', 'i' }, "<Right>", function() core_navigate("next") end, { noremap = true, nowait = true, silent = true })
keyset({ 'n', 'i' }, "<Left>", function() core_navigate("prev") end, { noremap = true, nowait = true, silent = true })
keyset({ 'n', 'i' }, "<Up>", function() core_navigate("recent") end, { noremap = true, silent = true })
keyset({ 'n', 'i' }, "<Down>", function() tabline_show_static_tabline() end, { noremap = true, silent = true })

return M
