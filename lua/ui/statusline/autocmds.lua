local api, fn = vim.api, vim.fn
local core = require("ui.statusline.core")

local function reload(buf, keys)
  for _, winid in ipairs(fn.win_findbuf(buf)) do
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
  callback = function(ev) reload(ev.buf, "diagnostics") end,
})

api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
  group = group,
  callback = function(ev) reload(ev.buf, "lsp_clients") end,
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

