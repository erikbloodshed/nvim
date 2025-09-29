local api = vim.api

local Switcher = require("ui.bufswitch.core")
local switcher = Switcher:new()

local function scheduled(func)
  return function(ev) vim.schedule(function() func(ev) end) end
end

local group = api.nvim_create_augroup("BufferSwitcher", { clear = true })

api.nvim_create_autocmd("BufEnter", {
  group = group,
  callback = scheduled(function(ev)
    switcher:on_buffer_enter(ev.buf)
  end),
})

api.nvim_create_autocmd("BufAdd", {
  group = group,
  callback = scheduled(function(ev)
    switcher:track_buffer(ev.buf)
  end),
})

api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
  group = group,
  callback = function(ev)
    switcher:remove_buffer(ev.buf)
  end,
})

switcher:initialize_buffers()

return {
  goto_next = function()
    switcher:goto("next")
  end,
  goto_prev = function()
    switcher:goto("prev")
  end,
  goto_recent = function()
    switcher:goto("recent")
  end,
  show_tabline = function()
    switcher:show_static_tabline()
  end,
}

