local api, fn = vim.api, vim.fn
local core = require("ui.statusline.core")

local debounce_timers = {}
local function debounced_reload(key, callback, delay)
  delay = delay or 50

  if debounce_timers[key] then
    debounce_timers[key]:stop()
  end

  debounce_timers[key] = vim.defer_fn(function()
    callback()
    debounce_timers[key] = nil
  end, delay)
end

local function reload(buf, keys, delay)
  local reload_key = buf .. "_" .. (type(keys) == "table" and table.concat(keys, ",") or keys)
  debounced_reload(reload_key, function()
    local windows = fn.win_findbuf(buf)
    if #windows == 0 then return end
    for _, winid in ipairs(windows) do
      if api.nvim_win_is_valid(winid) and core.win_data[winid] then
        core.get_win_cache(winid):reset(keys)
        local current_tab = api.nvim_get_current_tabpage()
        local tab_windows = api.nvim_tabpage_list_wins(current_tab)
        for _, tab_winid in ipairs(tab_windows) do
          if tab_winid == winid then
            core.refresh_win(winid)
            break
          end
        end
      end
    end
  end, delay)
end

local startup_phase = true
local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

vim.defer_fn(function()
  startup_phase = false
end, 1000)

local function get_delay()
  return startup_phase and 200 or 50
end

api.nvim_create_autocmd({ "BufWinEnter", "BufWritePost" }, {
  group = group,
  callback = function(ev)
    local keys = { "file_data", "file_status", "directory", "git_branch", "diagnostics", "lsp_clients" }
    reload(ev.buf, keys, get_delay())
  end,
})

api.nvim_create_autocmd("BufModifiedSet", {
  group = group,
  callback = function(ev)
    reload(ev.buf, "file_status", 20)
  end,
})

api.nvim_create_autocmd("DirChanged", {
  group = group,
  callback = function(ev)
    reload(ev.buf, { "directory", "git_branch" }, 100)
  end,
})

api.nvim_create_autocmd("DiagnosticChanged", {
  group = group,
  callback = function(ev)
    reload(ev.buf, "diagnostics", startup_phase and 300 or 100)
  end,
})

api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
  group = group,
  callback = function(ev)
    reload(ev.buf, "lsp_clients", 150)
  end,
})

local resize_timer = nil
api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
  group = group,
  callback = function()
    if resize_timer then
      resize_timer:stop()
    end

    resize_timer = vim.defer_fn(function()
      -- Only redraw if not in startup phase
      if not startup_phase then
        api.nvim_cmd({ cmd = "redrawstatus" }, {})
      end
      resize_timer = nil
    end, 100)
  end,
})

-- Window focus events (frequent during startup, debounce)
local focus_timer = nil
api.nvim_create_autocmd({ "WinEnter", "WinLeave" }, {
  group = group,
  callback = function()
    if focus_timer then
      focus_timer:stop()
    end

    focus_timer = vim.defer_fn(function()
      local winid = api.nvim_get_current_win()
      if api.nvim_win_is_valid(winid) then
        core.refresh_win(winid)
      end
      focus_timer = nil
    end, startup_phase and 150 or 30)
  end,
})

-- Window cleanup (immediate, no debouncing needed)
api.nvim_create_autocmd("WinClosed", {
  group = group,
  callback = function(ev)
    local winid = tonumber(ev.match)
    if winid and core.win_data[winid] then
      core.win_data[winid] = nil

      -- Clean up any pending timers for this window
      for key, timer in pairs(debounce_timers) do
        if key:find("^" .. winid .. "_") then
          timer:stop()
          debounce_timers[key] = nil
        end
      end
    end
  end,
})

vim.schedule(function()
  vim.defer_fn(function()
    api.nvim_create_autocmd("FocusGained", {
      group = group,
      callback = function()
        for _, winid in ipairs(api.nvim_list_wins()) do
          if api.nvim_win_is_valid(winid) and core.win_data[winid] then
            core.get_win_cache(winid):reset("git_branch")
          end
        end
      end,
    })

    api.nvim_create_autocmd("CursorMoved", {
      group = group,
      callback = function()
        local winid = api.nvim_get_current_win()
        if core.win_data[winid] then
          core.get_win_cache(winid):reset({ "position", "percentage" })
        end
      end,
    })
  end, 500)
end)

local function cleanup()
  for _, timer in pairs(debounce_timers) do
    if timer then timer:stop() end
  end
  debounce_timers = {}
  if resize_timer then resize_timer:stop() end
  if focus_timer then focus_timer:stop() end
end

if _G._statusline_autocmds_cleanup then
  _G._statusline_autocmds_cleanup()
end

_G._statusline_autocmds_cleanup = cleanup
