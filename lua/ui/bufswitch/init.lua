local api = vim.api
local insert = table.insert

local BufferSwitcher = require("ui.bufswitch.bufswitch")
local utils = require("ui.bufswitch.utils")

local M = {}
M.switcher = BufferSwitcher:new()

local function scheduled(current_buf)
  return function(ev) vim.schedule(function() current_buf(ev) end) end
end

local group = api.nvim_create_augroup('BufferSwitcher', { clear = true })
api.nvim_create_autocmd('BufEnter', {
  group = group,
  callback = scheduled(function(ev)
    M.switcher:on_buffer_enter(ev.buf)
  end)
})

api.nvim_create_autocmd('BufAdd', {
  group = group,
  callback = scheduled(function(ev)
    M.switcher:track_buffer(ev.buf)
  end)
})

api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
  group = group,
  callback = function(ev)
    M.switcher:remove_buffer(ev.buf)
  end
})

for _, b in ipairs(api.nvim_list_bufs()) do
  if utils.should_include_buffer(b) then
    insert(M.switcher.tabline_order, b)
  end
end

M.switcher:on_buffer_enter(api.nvim_get_current_buf())

return M
