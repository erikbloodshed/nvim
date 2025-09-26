local api = vim.api
local insert = table.insert

local BufferSwitcher = require("ui.bufswitch.bufswitch")
local utils = require("ui.bufswitch.utils")

local M = {}
local switcher = BufferSwitcher:new()

local function scheduled(current_buf)
  return function(ev) vim.schedule(function() current_buf(ev) end) end
end

local group_id = api.nvim_create_augroup('BufferSwitcher', { clear = true })
api.nvim_create_autocmd('BufEnter', {
  group = group_id,
  callback = scheduled(function(ev)
    switcher:on_buffer_enter(ev.buf)
  end)
})

api.nvim_create_autocmd('BufAdd', {
  group = group_id,
  callback = scheduled(function(ev)
    switcher:on_buffer_add(ev.buf)
  end)
})

api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
  group = group_id,
  callback = function(ev)
    switcher:on_buffer_remove(ev.buf)
  end
})

api.nvim_create_autocmd({ 'BufWritePost', 'BufModifiedSet' }, {
  group = group_id,
  callback = function(ev)
    switcher:on_buffer_modify(ev.buf)
  end
})

for _, b in ipairs(api.nvim_list_bufs()) do
  if utils.should_include_buffer(b) then
    insert(switcher.tabline_order, b)
  end
end

switcher:on_buffer_enter(api.nvim_get_current_buf())
switcher:init()

-- Public API
function M.next()
  switcher:navigate("next")
end

function M.prev()
  switcher:navigate("prev")
end

function M.recent()
  switcher:navigate("recent")
end

function M.show_buffers()
  switcher:show_static_tabline()
end

function M._get_switcher()
  return switcher
end

return M
