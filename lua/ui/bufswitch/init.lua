local api = vim.api
local M = {}

local BufSwitcher = require("ui.bufswitch.core")
local switcher = BufSwitcher:new()

local function scheduled(func)
  return function(ev)
    vim.schedule(function()
      func(ev)
    end)
  end
end

local group = api.nvim_create_augroup("BufSwitcher", { clear = true })

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

function M.goto_next()
  switcher:goto("next")
end
function M.goto_prev()
  switcher:goto("prev")
end
function M.goto_recent()
  switcher:goto("recent")
end
function M.show_tabline()
  switcher:show_tabline("temp")
end

switcher:init_buffers()
switcher:on_buffer_enter(api.nvim_get_current_buf())

return M
