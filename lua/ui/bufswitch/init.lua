local api = vim.api
local insert = table.insert

local core = require("ui.bufswitch.core")
local ui = require("ui.bufswitch.ui")
local utils = require("ui.bufswitch.utils")
local state = require("ui.bufswitch.state")

local M = {}

local function scheduled(cb)
  return function(ev) vim.schedule(function() cb(ev) end) end
end

-- Setup autocommands
local ag = api.nvim_create_augroup('BufferSwitcher', { clear = true })

api.nvim_create_autocmd('BufEnter', {
  group = ag,
  callback = scheduled(function(ev)
    core.on_buffer_enter(ev.buf)
  end)
})

api.nvim_create_autocmd('BufAdd', {
  group = ag,
  callback = scheduled(function(ev)
    core.on_buffer_add(ev.buf)
  end)
})

api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
  group = ag,
  callback = function(ev)
    core.on_buffer_remove(ev.buf)
  end
})

api.nvim_create_autocmd({ 'BufWritePost', 'BufModifiedSet' }, {
  group = ag,
  callback = function(ev)
    core.on_buffer_modify(ev.buf)
  end
})

-- Initialize existing buffers
for _, b in ipairs(api.nvim_list_bufs()) do
  if utils.should_include_buffer(b) then
    insert(state.data.tabline_order, b)
  end
end

core.on_buffer_enter(api.nvim_get_current_buf())
ui.init()

-- Public API
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
  ui.show_static_tabline(state.data.tabline_order)
end

return M
