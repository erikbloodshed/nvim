local api, fn = vim.api, vim.fn
local insert, remove = table.insert, table.remove

-- Require local modules
local config = require("ui.bufswitch.config").config
local ui = require("ui.bufswitch.ui")

local M = {}

-- State (now part of the exported module)
M.state = {
  buf_order = {},     -- Most-recently-used (MRU) order
  tabline_order = {}, -- Display order (matches tab order)
  cycle = { active = false, index = 0 },
}

-- Utility ---------------------------------------------------------------
local function remove_item(tbl, val)
  for i, x in ipairs(tbl) do
    if x == val then
      remove(tbl, i); return
    end
  end
end

local function is_empty_unnamed(buf)
  if not api.nvim_buf_is_valid(buf) or
    fn.bufname(buf) ~= "" or fn.getbufvar(buf, '&modified') ~= 0 then
    return false
  end
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
  for _, pat in ipairs(config.special_bufname_patterns) do
    if fn.bufname(buf):match(pat) then return true end
  end
  return fn.win_gettype() ~= ""
end

function M.include(buf)
  return api.nvim_buf_is_valid(buf) and fn.buflisted(buf) == 1 and not is_special(buf) and not skip_unnamed(buf)
end

function M.update_mru(buf)
  if M.include(buf) then
    remove_item(M.state.buf_order, buf)
    insert(M.state.buf_order, 1, buf) -- Insert at the beginning for MRU
  end
end

function M.remove_buf(buf)
  remove_item(M.state.buf_order, buf)
  remove_item(M.state.tabline_order, buf)
  ui.invalidate(buf)
end

local function end_cycle()
  if not M.state.cycle.active then return end
  ui.stop_timer()
  vim.o.showtabline = 0
  local f = M.state.tabline_order[M.state.cycle.index]
  M.state.cycle.active, M.state.cycle.index = false, 0
  if f and api.nvim_buf_is_valid(f) then M.update_mru(f) end
  if config.show_tabline then ui.update(M.state.tabline_order) end
end

function M.navigate(move)
  if config.disable_in_special and is_special() then return end
  ui.stop_timer()

  if not M.state.cycle.active then
    if #M.state.tabline_order < 2 then
      ui.show_temp(M.state.tabline_order)
      return
    end
    M.state.cycle.active = true
    M.state.cycle.index = 0
    for i, b in ipairs(M.state.tabline_order) do
      if b == api.nvim_get_current_buf() then
        M.state.cycle.index = i; break
      end
    end
    if M.state.cycle.index == 0 then M.state.cycle.index = 1 end
  end

  if move == "recent" then
    local n = #M.state.buf_order
    if n < 2 then return end
    local target = (api.nvim_get_current_buf() == M.state.buf_order[1]) and M.state.buf_order[2] or M.state.buf_order[1]
    for i, b in ipairs(M.state.tabline_order) do
      if b == target then
        M.state.cycle.index = i; break
      end
    end
  else
    local step = (move == "prev") and -1 or 1
    M.state.cycle.index = M.state.cycle.index + step
    if M.state.cycle.index < 1 then
      if not config.wrap_around then
        ui.show_temp(M.state.tabline_order); return
      end
      M.state.cycle.index = #M.state.tabline_order
    elseif M.state.cycle.index > #M.state.tabline_order then
      if not config.wrap_around then
        ui.show_temp(M.state.tabline_order); return
      end
      M.state.cycle.index = 1
    end
  end

  local t = M.state.tabline_order[M.state.cycle.index]
  if not (t and api.nvim_buf_is_valid(t)) then
    end_cycle()
    return
  end
  vim.cmd('buffer ' .. t)
  vim.o.showtabline = 2
  ui.update(M.state.tabline_order, M.state.cycle.index)
  ui.start_timer(config.hide_timeout, end_cycle)
end

return M
