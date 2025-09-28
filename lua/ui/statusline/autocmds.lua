-- ui/statusline/autocmds.lua

local api = vim.api
local core = require("ui.statusline.core")

---@diagnostic disable:need-check-nil
local function debounce(func, timeout)
  local timer = vim.uv.new_timer()
  local running = false
  return function(...)
    local argv = { ... }
    if running then timer:stop() end
    running = true
    timer:start(timeout, 0, function()
      running = false
      vim.schedule(function() func(unpack(argv)) end)
    end)
  end
end

local function reload(buf, keys)
  if not buf or buf == 0 or not api.nvim_buf_is_valid(buf) then return end
  for _, winid in ipairs(vim.fn.win_findbuf(buf)) do
    if core.win_data[winid] then
      core.get_win_cache(winid):reset(keys)
    end
    core.refresh_win(winid)
  end
end

local M = {}
local is_setup = false

-- The setup function to be called by init.lua
function M.setup(events_map)
  if is_setup then return end
  is_setup = true

  local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

  -- 1. Create component-based autocmds from the provided map
  for event, keys_set in pairs(events_map) do
    local keys_to_reload = {}
    for k in pairs(keys_set) do
      table.insert(keys_to_reload, k)
    end

    local callback = function(ev) reload(ev.buf, keys_to_reload) end

    if event == "DiagnosticChanged" or event == "LspAttach" or event == "LspDetach" then
      callback = debounce(callback, 100)
    end

    api.nvim_create_autocmd(event, {
      group = group,
      callback = callback,
    })
  end

  -- 2. Create general, non-component-specific autocmds
  api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = group,
    callback = function() api.nvim_cmd({ cmd = "redrawstatus" }, {}) end,
  })

  api.nvim_create_autocmd({ "WinEnter", "WinLeave" }, {
    group = group,
    callback = function()
      core.refresh_win(api.nvim_get_current_win())
    end,
  })

  api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(ev)
      local winid = tonumber(ev.match)
      if winid then core.win_data[winid] = nil end
    end,
  })
end

return M
