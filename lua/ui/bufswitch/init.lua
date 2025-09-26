local api = vim.api
local insert = table.insert

local config = require("ui.bufswitch.config")
local core = require("ui.bufswitch.core")
local ui = require("ui.bufswitch.ui")

local M = {}

local state = core.state

local function scheduled(cb)
  return function(ev) vim.schedule(function() cb(ev) end) end
end

local ag = api.nvim_create_augroup('BufferSwitcher', { clear = true })
api.nvim_create_autocmd('BufEnter', {
  group = ag,
  callback = scheduled(function()
    if not state.cycle.active then
      core.update_mru(api.nvim_get_current_buf())
      if config.show_tabline then
        local apply_hl = api.nvim_win_is_valid(api.nvim_get_current_win())
        ui.update(state.tabline_order, nil, apply_hl)
      end
    end
  end)
})
api.nvim_create_autocmd('BufAdd', {
  group = ag,
  callback = scheduled(function(ev)
    if not state.cycle.active and core.include(ev.buf) then
      insert(state.tabline_order, ev.buf)
      core.update_mru(ev.buf)
    end
  end)
})
api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' },
  { group = ag, callback = function(ev) core.remove_buf(ev.buf) end })
api.nvim_create_autocmd({ 'BufWritePost', 'BufModifiedSet' },
  { group = ag, callback = function(ev) ui.invalidate(ev.buf) end })

for _, b in ipairs(api.nvim_list_bufs()) do
  if core.include(b) then insert(state.tabline_order, b) end
end

core.update_mru(api.nvim_get_current_buf())
ui.init()

function M.next()
  core.navigate("next")
end

function M.prev()
  core.navigate("prev")
end

function M.recent()
  core.navigate("recent")
end

function M.show_buffers()
  ui.show_static(state.tabline_order)
end

return M
