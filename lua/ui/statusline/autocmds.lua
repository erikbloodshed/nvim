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
  for _, winid in ipairs(vim.fn.win_findbuf(buf)) do
    if core.win_data[winid] then
      core.get_win_cache(winid):reset(keys)
    end
    core.refresh_win(winid)
  end
end

local group = api.nvim_create_augroup("CustomStatusline", { clear = true })
local keys = { "file_data", "file_status", "directory", "git_branch", "diagnostics", "lsp_clients" }

api.nvim_create_autocmd({ "BufWinEnter", "BufWritePost" }, {
  group = group,
  callback = function(ev) reload(ev.buf, keys) end,
})

api.nvim_create_autocmd("BufModifiedSet", {
  group = group,
  callback = function(ev) reload(ev.buf, "file_status") end,
})

api.nvim_create_autocmd("DirChanged", {
  group = group,
  callback = function(ev) reload(ev.buf, { "directory", "git_branch" }) end,
})

api.nvim_create_autocmd("DiagnosticChanged", {
  group = group,
  callback = debounce(function(ev) reload(ev.buf, "diagnostics") end, 100)
})

api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
  group = group,
  callback = debounce(function(ev) reload(ev.buf, "lsp_clients") end, 100)
})

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
