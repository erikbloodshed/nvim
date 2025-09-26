local api, fn = vim.api, vim.fn
local insert, concat = table.insert, table.concat
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local utils = require("ui.bufswitch.utils")

local BufferSwitcher = {}
BufferSwitcher.__index = BufferSwitcher

function BufferSwitcher:new()
  local instance = {
    config = require("ui.bufswitch.config"),
    buf_order = {},
    tabline_order = {},
    cycle = { active = false, index = 0 },
    cache = {
      bufinfo = {},
      tabline = { content = "", timestamp = 0, hash = "", window_start = 1 },
      static_tabline = { content = "", timestamp = 0, hash = "", window_start = 1 },
    },
    hide_timer = nil,
    update_timer = nil,
    cache_ttl = 5000,
    debounce_delay = 16,
    tabline_ttl = 100,
    max_cache_size = 100,
    max_name_length = 16,
    format_expr = "%%#%s#%s%%*",
  }

  setmetatable(instance, self)
  return instance
end

function BufferSwitcher:reset_cycle()
  self.cycle.active = false
  self.cycle.index = 0
end

function BufferSwitcher:set_cycle(index)
  self.cycle.active = true
  self.cycle.index = index
end

function BufferSwitcher:is_cycling()
  return self.cycle.active
end

function BufferSwitcher:should_apply_hl()
  local current_win = api.nvim_get_current_win()
  return not (self.config.disable_in_special and utils.is_special(nil)) and
    api.nvim_win_is_valid(current_win)
end

function BufferSwitcher:update_mru(buf)
  if utils.should_include_buffer(buf) then
    utils.remove_item(self.buf_order, buf)
    insert(self.buf_order, 1, buf)
  end
end

function BufferSwitcher:remove_buffer(buf)
  utils.remove_item(self.buf_order, buf)
  utils.remove_item(self.tabline_order, buf)
  self:invalidate_buffer(buf)
end

function BufferSwitcher:add_buffer(buf)
  if not self:is_cycling() and utils.should_include_buffer(buf) then
    insert(self.tabline_order, buf)
    self:update_mru(buf)
    return true
  end
  return false
end

function BufferSwitcher:get_navigation_target()
  local n = #self.buf_order
  if n < 2 then return nil end
  local current = api.nvim_get_current_buf()
  local target = (current == self.buf_order[1]) and self.buf_order[2] or self.buf_order[1]

  for i, b in ipairs(self.tabline_order) do
    if b == target then return i end
  end
  return nil
end

function BufferSwitcher:calculate_cycle_index(move)
  if move == "recent" then
    return self:get_navigation_target()
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

function BufferSwitcher:initialize_cycle()
  if self:is_cycling() then return false end
  if #self.tabline_order < 2 then return false end

  local current_buf = api.nvim_get_current_buf()
  local index = 0

  for i, b in ipairs(self.tabline_order) do
    if b == current_buf then
      index = i
      break
    end
  end

  if index == 0 then index = 1 end
  self:set_cycle(index)
  return true
end

function BufferSwitcher:now()
  return fn.reltimefloat(fn.reltime()) * 1000
end

function BufferSwitcher:is_fresh(entry, ttl)
  return entry and (self:now() - (entry.timestamp or 0) < (ttl or self.cache_ttl))
end

function BufferSwitcher:cache_entry(result)
  return { result = result, timestamp = self:now() }
end

function BufferSwitcher:reset_cache(tbl)
  tbl.content, tbl.timestamp, tbl.hash, tbl.window_start = "", 0, "", 1
end

function BufferSwitcher:cleanup_cache()
  local count = 0
  for _ in pairs(self.cache.bufinfo) do count = count + 1 end
  if count > self.max_cache_size then
    for k, e in pairs(self.cache.bufinfo) do
      if not self:is_fresh(e) then self.cache.bufinfo[k] = nil end
    end
  end
end

function BufferSwitcher:invalidate_buffer(buf)
  self.cache.bufinfo[buf] = nil
  self:reset_cache(self.cache.tabline)
  self:reset_cache(self.cache.static_tabline)
end

function BufferSwitcher:hl_rule(content, hl, apply_hl)
  if not apply_hl or not hl or not content then return content or "" end
  return string.format(self.format_expr, hl, content)
end

function BufferSwitcher:get_buffer_info(buf)
  local c = self.cache.bufinfo[buf]
  if self:is_fresh(c) then return c.result end

  local name, bt = fn.bufname(buf) or "", vim.bo[buf].buftype
  local disp = vim.fs.basename(name) or "[No Name]"

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

  self.cache.bufinfo[buf] = self:cache_entry(info)
  return info
end

function BufferSwitcher:format_buffer(info, is_current, apply_hl)
  if not info then return self:hl_rule("[Invalid]", "BufSwitchInactive", apply_hl) end

  local parts = {}
  local base_hl = is_current and "BufSwitchSelected" or "BufSwitchInactive"

  if info.devicon then
    if apply_hl and info.icon_color then
      local hl_name = string.format("BufSwitchDevicon_%s_%s",
        info.icon_color:gsub("#", ""), is_current and "sel" or "inact")

      local base_hl_attrs = api.nvim_get_hl(0, { name = base_hl, link = false })
      api.nvim_set_hl(0, hl_name, { fg = info.icon_color, bg = base_hl_attrs.bg })

      insert(parts, self:hl_rule(info.devicon, hl_name, true))
    else
      insert(parts, self:hl_rule(info.devicon, base_hl, apply_hl))
    end
    insert(parts, self:hl_rule(" ", base_hl, apply_hl))
  end

  insert(parts, self:hl_rule(info.display_name, base_hl, apply_hl))
  return concat(parts)
end

function BufferSwitcher:hash_state(list, idx, apply_hl)
  if not next(list) then return "" end
  return string.format("%d:%s:%d:%s", api.nvim_get_current_buf(),
    concat(list, "-"), idx or 0, tostring(apply_hl))
end

function BufferSwitcher:calculate_bounds(cur, total, win, ref)
  if total <= win then return 1, total end
  local s = ref.window_start or 1
  if cur > s + win - 1 then s = cur - win + 1 elseif cur < s then s = cur end
  s = math.max(1, math.min(s, total - win + 1))
  ref.window_start = s
  return s, math.min(s + win - 1, total)
end

function BufferSwitcher:find_current_index(order, cur, cyc)
  if cyc and cyc > 0 then return cyc end
  for i, b in ipairs(order) do if b == cur then return i end end
  return #order > 0 and 1 or 0
end

function BufferSwitcher:render_tabline(order, cyc_idx, ref, ttl, apply_hl)
  apply_hl = apply_hl == nil and true or apply_hl
  local h = self:hash_state(order, cyc_idx, apply_hl)
  if ref.hash == h and self:is_fresh(ref, ttl) then return ref.content end

  local total = #order
  if total == 0 then
    return self:hl_rule("%T", "BufSwitchFill", apply_hl)
  end

  local cur_buf = api.nvim_get_current_buf()
  local cur_idx = self:find_current_index(order, cur_buf, cyc_idx)
  local s, e = self:calculate_bounds(cur_idx, total, self.config.tabline_display_window, ref)

  local parts = { self:hl_rule("", "BufSwitchFill", apply_hl) }

  if s > 1 then
    insert(parts, self:hl_rule("<.. ", "BufSwitchSeparator", apply_hl))
  end

  for i = s, e do
    local b = order[i]
    if api.nvim_buf_is_valid(b) then
      local info = self:get_buffer_info(b)
      local is_current = (cyc_idx and i == cyc_idx) or b == cur_buf

      if info then
        if i > s then
          insert(parts, self:hl_rule("|", "BufSwitchSeparator", apply_hl))
        end

        local buffer_hl = is_current and "BufSwitchSelected" or "BufSwitchInactive"
        local formatted_name = self:format_buffer(info, is_current, apply_hl)
        insert(parts, self:hl_rule("  ", buffer_hl, apply_hl) .. formatted_name ..
          self:hl_rule("  ", buffer_hl, apply_hl))
      end
    end
  end

  if e < total then
    insert(parts, self:hl_rule("| ..>", "BufSwitchSeparator", apply_hl))
  end

  insert(parts, self:hl_rule("%T", "BufSwitchFill", apply_hl))

  local out = concat(parts, "")
  ref.content, ref.timestamp, ref.hash = out, self:now(), h
  return out
end

function BufferSwitcher:stop_timer(timer)
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
  return nil
end

function BufferSwitcher:start_hide_timer(timeout, cb)
  self.hide_timer = self:stop_timer(self.hide_timer)
  self.hide_timer = vim.uv.new_timer()
  if self.hide_timer then
    self.hide_timer:start(timeout, 0, vim.schedule_wrap(cb))
  end
end

function BufferSwitcher:stop_hide_timer()
  self.hide_timer = self:stop_timer(self.hide_timer)
end

function BufferSwitcher:update_tabline(cyc_idx, apply_hl)
  vim.o.tabline = self:render_tabline(self.tabline_order, cyc_idx,
    self.cache.tabline, self.tabline_ttl, apply_hl)
end

function BufferSwitcher:update_tabline_debounced(apply_hl)
  self.update_timer = self.update_timer or vim.uv.new_timer()
  if self.update_timer then
    self.update_timer:stop()
    self.update_timer:start(self.debounce_delay, 0, vim.schedule_wrap(function()
      self:update_tabline(nil, apply_hl)
      self.update_timer:stop()
    end))
  end
end

function BufferSwitcher:show_temporary_tabline(apply_hl)
  self:stop_hide_timer()
  vim.o.showtabline = 2
  self:update_tabline_debounced(apply_hl)
  self:start_hide_timer(self.config.hide_timeout, function()
    vim.o.showtabline = 0
  end)
end

function BufferSwitcher:show_static_tabline(apply_hl)
  self:stop_hide_timer()
  vim.o.showtabline = 2
  vim.o.tabline = self:render_tabline(self.tabline_order, nil,
    self.cache.static_tabline, self.tabline_ttl, apply_hl)
  self:start_hide_timer(self.config.hide_timeout, function()
    vim.o.showtabline = 0
  end)
end

function BufferSwitcher:end_cycle()
  if not self:is_cycling() then return end

  self:stop_hide_timer()
  vim.o.showtabline = 0

  local target_buf = self.tabline_order[self.cycle.index]
  self:reset_cycle()

  if target_buf and api.nvim_buf_is_valid(target_buf) then
    self:update_mru(target_buf)
  end

  if self.config.show_tabline then
    self:update_tabline(nil, self:should_apply_hl())
  end
end

function BufferSwitcher:navigate(move)
  if self.config.disable_in_special and utils.is_special(nil) then
    return
  end

  self:stop_hide_timer()
  local apply_hl = self:should_apply_hl()

  if not self:is_cycling() then
    if not self:initialize_cycle() then
      self:show_temporary_tabline(apply_hl)
      return
    end
  end

  local new_index = self:calculate_cycle_index(move)
  if not new_index then
    self:show_temporary_tabline(apply_hl)
    return
  end

  self.cycle.index = new_index
  local target_buf = self.tabline_order[new_index]

  if not (target_buf and api.nvim_buf_is_valid(target_buf)) then
    self:end_cycle()
    return
  end

  vim.cmd('buffer ' .. target_buf)
  vim.o.showtabline = 2
  self:update_tabline(new_index, apply_hl)
  self:start_hide_timer(self.config.hide_timeout, function()
    self:end_cycle()
  end)
end

function BufferSwitcher:on_buffer_enter(buf)
  if not self:is_cycling() then
    self:update_mru(buf)
    if self.config.show_tabline then
      local apply_hl = api.nvim_win_is_valid(api.nvim_get_current_win())
      self:update_tabline(nil, apply_hl)
    end
  end
end

function BufferSwitcher:on_buffer_add(buf)
  self:add_buffer(buf)
end

function BufferSwitcher:on_buffer_remove(buf)
  self:remove_buffer(buf)
end

function BufferSwitcher:on_buffer_modify(buf)
  self:invalidate_buffer(buf)
end

function BufferSwitcher:init()
  if self.config.periodic_cleanup then
    fn.timer_start(30000, function() self:cleanup_cache() end, { ['repeat'] = -1 })
  end
end

return BufferSwitcher
