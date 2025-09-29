local api, fn = vim.api, vim.fn
local has_devicons, devicons = pcall(require, "nvim-web-devicons")
local utils = require("ui.bufswitch.utils")

local BufSwitcher = {}
BufSwitcher.__index = BufSwitcher

function BufSwitcher:new()
  local instance = {
    config = require("ui.bufswitch.config"),
    buf_order = {},
    hl_cache = {},
    tabline_order = {},
    buf_order_index = {},
    tabline_order_index = {},
    cycle = { active = false, index = 0 },
    cache = {
      bufinfo = {},
      tabline = { content = "", version = -1, cycle_idx = 0, window_start = 1 },
      static_tabline = { content = "", version = -1, cycle_idx = 0, window_start = 1 },
    },
    hide_timer = nil,
    update_timer = nil,
    max_name_length = 16,
    format_expr = "%%#%s#%s%%*",
    state_version = 0,
    parts_buffer = {},
  }
  setmetatable(instance, self)
  return instance
end

function BufSwitcher:rebuild_index(order_table, index_table)
  for k in pairs(index_table) do
    index_table[k] = nil
  end
  for i, buf in ipairs(order_table) do
    index_table[buf] = i
  end
end

function BufSwitcher:is_cycling()
  return self.cycle.active
end

local cached_win
local cached_win_frame = 0
function BufSwitcher:should_apply_hl()
  local frame = vim.fn.localtime()
  if frame ~= cached_win_frame then
    cached_win = api.nvim_get_current_win()
    cached_win_frame = frame
  end
  return not (self.config.disable_in_special and utils.is_special(nil)) and api.nvim_win_is_valid(cached_win)
end

local function bump_version(self)
  self.state_version = self.state_version + 1
end

local function update_indices_from(tbl, index_tbl, start_pos)
  for i = start_pos, #tbl do
    index_tbl[tbl[i]] = i
  end
end

function BufSwitcher:track_buffer(buf)
  if not utils.should_include_buffer(buf) then
    return false
  end
  local old_pos = self.buf_order_index[buf]
  if old_pos then
    table.remove(self.buf_order, old_pos)
    update_indices_from(self.buf_order, self.buf_order_index, old_pos)
  end
  table.insert(self.buf_order, 1, buf)
  self.buf_order_index[buf] = 1
  local limit = math.min(old_pos or (#self.buf_order + 1), #self.buf_order)
  for i = 2, limit do
    self.buf_order_index[self.buf_order[i]] = i
  end
  if not self:is_cycling() and not self.tabline_order_index[buf] then
    table.insert(self.tabline_order, buf)
    self.tabline_order_index[buf] = #self.tabline_order
  end
  bump_version(self)
  return true
end

function BufSwitcher:remove_buffer(buf)
  local pos = self.buf_order_index[buf]
  if pos then
    table.remove(self.buf_order, pos)
    self.buf_order_index[buf] = nil
    update_indices_from(self.buf_order, self.buf_order_index, pos)
  end
  local tpos = self.tabline_order_index[buf]
  if tpos then
    table.remove(self.tabline_order, tpos)
    self.tabline_order_index[buf] = nil
    update_indices_from(self.tabline_order, self.tabline_order_index, tpos)
  end
  self:invalidate_buffer(buf)
  bump_version(self)
end

function BufSwitcher:get_goto_target()
  if #self.buf_order < 2 then
    return nil
  end
  local current = api.nvim_get_current_buf()
  local target = (current == self.buf_order[1]) and self.buf_order[2] or self.buf_order[1]
  return self.tabline_order_index[target]
end

function BufSwitcher:calc_cycle_index(move)
  if move == "recent" then
    return self:get_goto_target()
  end
  local step = (move == "prev") and -1 or 1
  local new_index = self.cycle.index + step
  local max_index = #self.tabline_order
  if new_index < 1 then
    return self.config.wrap_around and max_index or nil
  elseif new_index > max_index then
    return self.config.wrap_around and 1 or nil
  end
  return new_index
end

function BufSwitcher:initialize_cycle()
  if self:is_cycling() or #self.tabline_order < 2 then
    return false
  end
  local current_buf = api.nvim_get_current_buf()
  local index = self.tabline_order_index[current_buf] or 1
  self.cycle.active = true
  self.cycle.index = index
  return true
end

function BufSwitcher:invalidate_buffer(buf)
  self.cache.bufinfo[buf] = nil
  for _, c in pairs({ self.cache.tabline, self.cache.static_tabline }) do
    c.content, c.version, c.cycle_idx, c.window_start = "", -1, 0, 1
  end
  if vim.tbl_count(self.hl_cache) > 100 then
    self.hl_cache = {}
  end
  bump_version(self)
end

function BufSwitcher:hl_rule(content, hl, apply_hl)
  if not apply_hl or not hl or not content then
    return content or ""
  end
  return string.format(self.format_expr, hl, content)
end

function BufSwitcher:get_icon_hl(base_hl, color)
  if not color then
    return base_hl
  end
  local cache_key = base_hl .. "_" .. color
  if self.hl_cache[cache_key] then
    return self.hl_cache[cache_key]
  end
  local hl_name = string.format("BufSwitchDevicon_%s_sel", color:gsub("#", ""))
  local ok, base_hl_attrs = pcall(api.nvim_get_hl, 0, { name = base_hl, link = false })
  local bg = ok and base_hl_attrs and base_hl_attrs.bg or nil
  api.nvim_set_hl(0, hl_name, { fg = color, bg = bg })
  self.hl_cache[cache_key] = hl_name
  return hl_name
end

function BufSwitcher:get_buffer_info(buf)
  local c = self.cache.bufinfo[buf]
  if c then
    return c.result
  end
  local name, bt = fn.bufname(buf) or "", vim.bo[buf].buftype
  local disp = (name == "") and "[No Name]" or vim.fs.basename(name)
  if bt == "help" then
    disp = "[Help] " .. (disp ~= "[No Name]" and disp or "help")
  elseif bt == "terminal" then
    disp = "[Term] " .. (disp ~= "[No Name]" and disp:gsub("^term://.*//", "") or "terminal")
  end
  if #disp > self.max_name_length then
    disp = disp:sub(1, self.max_name_length - 3) .. "..."
  end
  local info = { display_name = disp }
  if has_devicons then
    info.devicon, info.icon_color = devicons.get_icon_color(disp, fn.fnamemodify(name, ":e") or "")
  end
  self.cache.bufinfo[buf] = { result = info }
  return info
end

function BufSwitcher:format_buffer(info, is_current, apply_hl)
  if not info then
    return self:hl_rule("[Invalid]", "BufSwitchInactive", apply_hl)
  end
  local parts = self.parts_buffer
  for i = 1, #parts do
    parts[i] = nil
  end
  local base_hl = is_current and "BufSwitchSelected" or "BufSwitchInactive"
  if info.devicon then
    if is_current and apply_hl and info.icon_color then
      local hl_name = self:get_icon_hl(base_hl, info.icon_color)
      parts[#parts + 1] = self:hl_rule(info.devicon, hl_name, true)
    else
      parts[#parts + 1] = self:hl_rule(info.devicon, base_hl, apply_hl)
    end
    parts[#parts + 1] = self:hl_rule(" ", base_hl, apply_hl)
  end
  parts[#parts + 1] = self:hl_rule(info.display_name, base_hl, apply_hl)
  return table.concat(parts)
end

function BufSwitcher:calculate_bounds(cur, total, win, ref)
  if total <= win then
    return 1, total
  end
  local s = ref.window_start or 1
  if cur > s + win - 1 then
    s = cur - win + 1
  elseif cur < s then
    s = cur
  end
  s = math.max(1, math.min(s, total - win + 1))
  ref.window_start = s
  return s, math.min(s + win - 1, total)
end

function BufSwitcher:find_current_index(order, cur, cyc)
  if cyc and cyc > 0 then
    return cyc
  end
  local idx = self.tabline_order_index[cur]
  if idx then
    return idx
  end
  return #order > 0 and 1 or 0
end

function BufSwitcher:render(order, cyc_idx, ref, apply_hl)
  apply_hl = apply_hl == nil and true or apply_hl
  if ref.version == self.state_version and ref.cycle_idx == (cyc_idx or 0) then
    return ref.content
  end
  local total = #order
  if total == 0 then
    return self:hl_rule("%T", "BufSwitchFill", apply_hl)
  end
  local cur_buf = api.nvim_get_current_buf()
  local cur_idx = self:find_current_index(order, cur_buf, cyc_idx)
  local s, e = self:calculate_bounds(cur_idx, total, self.config.tabline_display_window, ref)
  local parts = { self:hl_rule("", "BufSwitchFill", apply_hl) }
  if s > 1 then
    parts[#parts + 1] = self:hl_rule("<.. ", "BufSwitchSeparator", apply_hl)
  end
  for i = s, e do
    local b = order[i]
    if api.nvim_buf_is_valid(b) then
      local info = self:get_buffer_info(b)
      local is_current = (cyc_idx and i == cyc_idx) or b == cur_buf
      if info then
        if i > s then
          parts[#parts + 1] = self:hl_rule("|", "BufSwitchSeparator", apply_hl)
        end
        local buffer_hl = is_current and "BufSwitchSelected" or "BufSwitchInactive"
        local formatted_name = self:format_buffer(info, is_current, apply_hl)
        parts[#parts + 1] = self:hl_rule("  ", buffer_hl, apply_hl)
          .. formatted_name
          .. self:hl_rule("  ", buffer_hl, apply_hl)
      end
    end
  end
  if e < total then
    parts[#parts + 1] = self:hl_rule("| ..>", "BufSwitchSeparator", apply_hl)
  end
  parts[#parts + 1] = self:hl_rule("%T", "BufSwitchFill", apply_hl)
  local out = table.concat(parts)
  ref.content, ref.version, ref.cycle_idx = out, self.state_version, cyc_idx or 0
  return out
end

function BufSwitcher:stop_timer(timer)
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
  return nil
end

function BufSwitcher:restart_timer(name, timeout, cb, one_shot)
  local timer = self[name]
  if not timer then
    timer = vim.uv.new_timer()
    self[name] = timer
  elseif not timer:is_closing() then
    timer:stop()
  else
    timer = vim.uv.new_timer()
    self[name] = timer
  end
  if timer then
    if one_shot == false then
      timer:start(timeout, timeout, vim.schedule_wrap(cb))
    else
      timer:start(timeout, 0, vim.schedule_wrap(cb))
    end
  end
end

function BufSwitcher:update(cyc_idx, apply_hl)
  vim.o.tabline = self:render(self.tabline_order, cyc_idx, self.cache.tabline, apply_hl)
end

function BufSwitcher:update_debounced(apply_hl)
  self.update_timer = self.update_timer or vim.uv.new_timer()
  if self.update_timer then
    self.update_timer:stop()
    self.update_timer:start(
      16,
      0,
      vim.schedule_wrap(function()
        self:update(nil, apply_hl)
        self.update_timer:stop()
      end)
    )
  end
end

function BufSwitcher:show_tabline(mode, apply_hl)
  self.hide_timer = self:stop_timer(self.hide_timer)
  vim.o.showtabline = 2
  if mode == "static" then
    vim.o.tabline = self:render(self.tabline_order, nil, self.cache.static_tabline, apply_hl)
  else
    self:update_debounced(apply_hl)
  end
  self:restart_timer("hide_timer", self.config.hide_timeout, function()
    vim.o.showtabline = 0
  end)
end

function BufSwitcher:end_cycle()
  if not self:is_cycling() then
    return
  end
  self.hide_timer = self:stop_timer(self.hide_timer)
  vim.o.showtabline = 0
  local target_buf = self.tabline_order[self.cycle.index]
  self.cycle.active = false
  self.cycle.index = 0
  if target_buf and api.nvim_buf_is_valid(target_buf) then
    self:track_buffer(target_buf)
  end
  if self.config.show_tabline then
    self:update(nil, self:should_apply_hl())
  end
end

function BufSwitcher:goto(move)
  if self.config.disable_in_special and utils.is_special(nil) then
    return
  end
  self.hide_timer = self:stop_timer(self.hide_timer)
  local apply_hl = self:should_apply_hl()
  if not self:is_cycling() then
    if not self:initialize_cycle() then
      self:show_tabline("temp", apply_hl)
      return
    end
  end
  local new_index = self:calc_cycle_index(move)
  if not new_index then
    self:show_tabline("temp", apply_hl)
    return
  end
  self.cycle.index = new_index
  local target_buf = self.tabline_order[new_index]
  if not (target_buf and api.nvim_buf_is_valid(target_buf)) then
    self:end_cycle()
    return
  end
  api.nvim_cmd({ cmd = "buffer", args = { target_buf } }, {})
  vim.o.showtabline = 2
  self:update(new_index, apply_hl)
  self:restart_timer("hide_timer", self.config.hide_timeout, function()
    self:end_cycle()
  end)
end

function BufSwitcher:init_buffers()
  for _, b in ipairs(api.nvim_list_bufs()) do
    if utils.should_include_buffer(b) then
      table.insert(self.tabline_order, b)
    end
  end
  self:rebuild_index(self.tabline_order, self.tabline_order_index)
end

function BufSwitcher:on_buffer_enter(buf)
  if not self:is_cycling() then
    self:track_buffer(buf)
    if self.config.show_tabline then
      local apply_hl = api.nvim_win_is_valid(api.nvim_get_current_win())
      self:update(nil, apply_hl)
    end
  end
end

return BufSwitcher
