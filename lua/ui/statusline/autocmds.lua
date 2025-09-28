local api = vim.api
local core = require("ui.statusline.core")

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

function M.setup(events_map)
  if is_setup then return end
  is_setup = true
  local group = api.nvim_create_augroup("CustomStatusline", { clear = true })
  for event, keys_set in pairs(events_map) do
    local keys_to_reload = vim.tbl_keys(keys_set)
    local callback = function(ev) reload(ev.buf, keys_to_reload) end
    api.nvim_create_autocmd(event, {
      group = group,
      callback = callback,
    })
  end
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
