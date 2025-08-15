local api, fn, loop = vim.api, vim.fn, vim.loop
local M = {}

local Cache = {}
Cache.__index = Cache

function Cache:new(ttl_map)
  return setmetatable({ data = {}, ts = {}, widths = {}, ttl = ttl_map or {}, }, self)
end

function Cache:now_ms()
  return loop.hrtime() / 1e6
end

function Cache:valid(key)
  local v = self.data[key]
  if v == nil then
    return false
  end
  local created = self.ts[key]
  if not created then
    return false
  end
  local ttl = self.ttl[key] or 1000
  return (self:now_ms() - created) < ttl
end

function Cache:update(key, value)
  self.data[key] = value
  self.ts[key] = self:now_ms()

  if type(value) == "string" then
    local plain = value:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", "")
    self.widths[key] = fn.strdisplaywidth(plain)
  else
    self.widths[key] = nil
  end
end

function Cache:get_or_set(key, fnc)
  if self:valid(key) then return self.data[key] end
  local ok, v = pcall(fnc)
  if not ok then v = "" end
  self:update(key, v)
  return v
end

function Cache:invalidate(keys)
  if not keys then return end
  if type(keys) == "string" then keys = { keys } end
  for _, k in ipairs(keys) do
    self.data[k] = nil
    self.ts[k] = nil
    self.widths[k] = nil
  end
end

-- Per-window caches and state
local window_caches = {}
local window_git_cache = {}
local window_git_jobs = {}
local window_file_icon_cache = {}
local window_file_icon_jobs = {}

-- Get or create cache for a specific window
local function get_window_cache(winid)
  if not window_caches[winid] then
    window_caches[winid] = Cache:new({
      mode = 50,
      file_info = 200,
      position = 100,
      percentage = 100,
      git_branch = 60000,
      diagnostics = 500,
      lsp_status = 2000,
      encoding = 120000,
      simple_title = 3000,
    })
  end
  return window_caches[winid]
end

-- Clean up cache for closed windows
local function cleanup_window_cache(winid)
  window_caches[winid] = nil
  window_git_cache[winid] = nil
  window_git_jobs[winid] = nil
  window_file_icon_cache[winid] = nil
  window_file_icon_jobs[winid] = nil
end

local config = {
  separators = { left = "", right = "", section = " │ " },
  throttle_ms = 50,
  icons = {
    modified = "[+]",
    readonly = "",
    git = "",
    lsp = "",
    error = "",
    warn = "󱈸",
    info = "",
    hint = "",
  },
  exclude = {
    buftypes = {
      terminal = true,
      prompt = true
    },
    filetypes = {
      ["neo-tree"] = true,
      lazy = true,
      lspinfo = true,
      checkhealth = true,
      help = true,
      man = true,
      qf = true,
    },
  },
}

local modes = {
  n = { " N ", "StatusLineNormal" },
  i = { " I ", "StatusLineInsert" },
  v = { " V ", "StatusLineVisual" },
  V = { " V ", "StatusLineVisual" },
  ["\22"] = { " V ", "StatusLineVisual" },
  c = { " C ", "StatusLineCommand" },
  R = { " R ", "StatusLineReplace" },
  r = { " R ", "StatusLineReplace" },
  s = { " S ", "StatusLineVisual" },
  S = { " S ", "StatusLineVisual" },
  ["\19"] = { " S ", "StatusLineVisual" },
  t = { " T ", "StatusLineTerminal" },
}

local function hl(name, text)
  return ("%%#%s#%s%%*"):format(name, text)
end

local loaded = {}
local require_safe = function(mod)
  if loaded[mod] ~= nil then
    return loaded[mod]
  end
  local ok, res = pcall(require, mod)
  loaded[mod] = ok and res or false
  return loaded[mod]
end

-- Per-window file icon handling
local function get_file_icon(winid, filename, extension)
  if not window_file_icon_cache[winid] then
    window_file_icon_cache[winid] = {}
  end
  if not window_file_icon_jobs[winid] then
    window_file_icon_jobs[winid] = {}
  end

  local cache_key = filename .. "." .. (extension or "")

  -- Return cached icon if available
  if window_file_icon_cache[winid][cache_key] then
    return window_file_icon_cache[winid][cache_key]
  end

  -- Prevent duplicate requests
  if window_file_icon_jobs[winid][cache_key] then
    return ""
  end

  window_file_icon_jobs[winid][cache_key] = true

  -- Load icon asynchronously
  vim.defer_fn(function()
    local devicons = require_safe("nvim-web-devicons")
    if devicons then
      -- Ensure setup is called if not already done
      if not devicons.has_loaded() then
        devicons.setup {}
      end

      local icon, hl_group = devicons.get_icon(filename, extension)
      if icon and icon ~= "" then
        local colored_icon = icon .. " "

        -- Use the highlight group provided by devicons
        if hl_group and hl_group ~= "" then
          colored_icon = hl(hl_group, icon) .. " "
        end

        window_file_icon_cache[winid][cache_key] = colored_icon
      else
        window_file_icon_cache[winid][cache_key] = ""
      end
      window_file_icon_jobs[winid][cache_key] = nil

      -- Invalidate file_info cache for this window only
      local cache = get_window_cache(winid)
      cache:invalidate("file_info")
      if api.nvim_win_is_valid(winid) then
        M.refresh_window(winid)
      end
    else
      window_file_icon_jobs[winid][cache_key] = nil
      window_file_icon_cache[winid][cache_key] = ""
    end
  end, 10)

  return ""
end

-- Per-window git branch handling
local function fetch_git_branch(winid, root)
  if not window_git_jobs[winid] then
    window_git_jobs[winid] = {}
  end

  if window_git_jobs[winid][root] then
    return
  end

  window_git_jobs[winid][root] = true

  local function on_exit(job_output)
    if not window_git_jobs[winid] then return end
    window_git_jobs[winid][root] = nil

    if not job_output or job_output.code ~= 0 or not job_output.stdout then
      return
    end

    local branch = job_output.stdout:gsub("%s*$", "")
    if not window_git_cache[winid] then
      window_git_cache[winid] = {}
    end
    window_git_cache[winid][root] = branch ~= "" and hl("StatusLineGit", config.icons.git .. " " .. branch) or ""

    local cache = get_window_cache(winid)
    cache:invalidate("git_branch")
    if api.nvim_win_is_valid(winid) then
      M.refresh_window(winid)
    end
  end

  vim.system(
    { "git", "symbolic-ref", "--short", "HEAD" },
    { cwd = root, text = true, timeout = 2000 },
    vim.schedule_wrap(on_exit)
  )
end

-- Component generators that work with specific window context
local function create_components(winid, bufnr)
  local cache = get_window_cache(winid)
  local C = {}

  C.mode = function()
    return cache:get_or_set("mode", function()
      local m = modes[(api.nvim_get_mode() or {}).mode] or { " ? ", "StatusLineNormal" }
      return hl(m[2], m[1])
    end)
  end

  C.file_info = function()
    return cache:get_or_set("file_info", function()
      local name = api.nvim_buf_get_name(bufnr)
      name = name == "" and "[No Name]" or fn.fnamemodify(name, ":t")

      local extension = fn.fnamemodify(name, ":e")
      local icon = get_file_icon(winid, name, extension)

      local comps = {}
      local readonly = api.nvim_get_option_value("readonly", { buf = bufnr })
      local modified = api.nvim_get_option_value("modified", { buf = bufnr })

      if readonly then
        comps[#comps + 1] = hl("StatusLineReadonly", config.icons.readonly .. " ")
      end
      comps[#comps + 1] = hl(modified and "StatusLineModified" or "StatusLineFile",
        icon .. name)
      if modified then
        comps[#comps + 1] = hl("StatusLineModified", " " .. config.icons.modified)
      end
      return table.concat(comps, "")
    end)
  end

  C.simple_title = function()
    return cache:get_or_set("simple_title", function()
      local bt = api.nvim_get_option_value("buftype", { buf = bufnr })
      local ft = api.nvim_get_option_value("filetype", { buf = bufnr })
      local title_map = {
        buftype = {
          terminal = "🖥 terminal",
        },
        filetype = {
          lazy = "💤 lazy",
          ["neo-tree"] = "🌳 neo-tree",
          ["neo-tree-popup"] = "🌳 neo-tree",
          lspinfo = "🔧 lsp info",
          checkhealth = "🩺 checkhealth",
          man = "📖 manual",
          qf = "📋 quickfix",
          help = "❓ help",
        },
      }

      local title = "no file"

      if title_map.buftype[bt] then
        title = title_map.buftype[bt]
      elseif title_map.filetype[ft] then
        title = title_map.filetype[ft]
      end

      return hl("String", title)
    end)
  end

  C.git_branch = function()
    return cache:get_or_set("git_branch", function()
      local buf_name = api.nvim_buf_get_name(bufnr)
      local buf_dir = buf_name ~= "" and fn.fnamemodify(buf_name, ":h") or fn.getcwd()
      local gitdir = vim.fs.find({ ".git" }, { upward = true, path = buf_dir })
      local root = ""
      if gitdir and gitdir[1] then
        root = vim.fs.dirname(gitdir[1])
      end

      if root == "" then return "" end

      if not window_git_cache[winid] then
        window_git_cache[winid] = {}
      end

      if window_git_cache[winid][root] then
        return window_git_cache[winid][root]
      end

      if not window_git_jobs[winid] then
        window_git_jobs[winid] = {}
      end

      if not window_git_jobs[winid][root] then
        -- schedule fetch (non-blocking)
        vim.defer_fn(function() fetch_git_branch(winid, root) end, 20)
      end
      return ""
    end)
  end

  C.diagnostics = function()
    return cache:get_or_set("diagnostics", function()
      local counts = vim.diagnostic.count(bufnr)
      local s = vim.diagnostic.severity
      local sev_map = {
        { s.ERROR, "StatusLineDiagError", config.icons.error },
        { s.WARN,  "StatusLineDiagWarn",  config.icons.warn },
        { s.INFO,  "StatusLineDiagInfo",  config.icons.info },
        { s.HINT,  "StatusLineDiagHint",  config.icons.hint },
      }
      local p = {}
      for _, v in ipairs(sev_map) do
        local c = counts[v[1]]
        if c and c > 0 then p[#p + 1] = hl(v[2], v[3] .. " " .. c) end
      end
      return table.concat(p, " ")
    end)
  end

  C.lsp_status = function()
    return cache:get_or_set("lsp_status", function()
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      if not clients or #clients == 0 then return "" end
      local names = {}
      for _, c in ipairs(clients) do names[#names + 1] = c.name end
      return hl("StatusLineLSP", config.icons.lsp .. " " .. table.concat(names, ", "))
    end)
  end

  C.position = function()
    return cache:get_or_set("position", function()
      if not api.nvim_win_is_valid(winid) then return "" end
      local pos = api.nvim_win_get_cursor(winid)
      return table.concat({
        hl("StatusLineLabel", "Ln "),
        hl("StatusLineValue", tostring(pos[1])),
        hl("StatusLineLabel", ", Col "),
        hl("StatusLineValue", tostring(pos[2] + 1))
      })
    end)
  end

  C.percentage = function()
    return cache:get_or_set("percentage", function()
      if not api.nvim_win_is_valid(winid) then return "" end
      local cur = api.nvim_win_get_cursor(winid)[1]
      local total = api.nvim_buf_line_count(bufnr)

      -- Handle edge cases
      if total <= 1 then
        return hl("StatusLineValue", "All")
      end

      local pct = math.floor((cur - 1) / (total - 1) * 100)

      -- Determine display value
      local display
      if pct <= 5 then
        display = "Top"
      elseif pct >= 95 then
        display = "Bot"
      elseif pct >= 45 and pct <= 55 then
        display = "Mid"
      else
        display = pct .. "%%"
      end

      return hl("StatusLineValue", display)
    end)
  end

  return C
end

local width_for = function(cache, key_or_str)
  if cache.widths[key_or_str] then return cache.widths[key_or_str] end
  if type(key_or_str) == "string" then
    local plain = key_or_str:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", "")
    return fn.strdisplaywidth(plain)
  end
  return 0
end

local is_excluded_buftype = function(win)
  if not api.nvim_win_is_valid(win) then return false end
  local buf = api.nvim_win_get_buf(win)
  local bt = api.nvim_get_option_value("buftype", { buf = buf })
  local ft = api.nvim_get_option_value("filetype", { buf = buf })
  return config.exclude.buftypes[bt] or config.exclude.filetypes[ft]
end

-- Window-specific refresh function
M.refresh_window = function(winid)
  if not api.nvim_win_is_valid(winid) then
    cleanup_window_cache(winid)
    return
  end

  local main_expr = string.format(
    '%%!v:lua.require("custom_ui.statusline").statusline_for_window(%d)',
    winid
  )
  local simple_expr = string.format(
    '%%!v:lua.require("custom_ui.statusline").simple_statusline_for_window(%d)',
    winid
  )

  if is_excluded_buftype(winid) then
    api.nvim_set_option_value("statusline", simple_expr, { win = winid })
  else
    api.nvim_set_option_value("statusline", main_expr, { win = winid })
  end
end

-- Refresh all windows (fallback)
M.refresh = function(win)
  if win then
    M.refresh_window(win)
  else
    for _, w in ipairs(api.nvim_list_wins()) do
      M.refresh_window(w)
    end
  end
end

-- Window-specific statusline builders
M.simple_statusline_for_window = function(winid)
  if not api.nvim_win_is_valid(winid) then return "" end
  local bufnr = api.nvim_win_get_buf(winid)
  local C = create_components(winid, bufnr)
  local center = C.simple_title()
  return "%=" .. center .. "%="
end

M.statusline_for_window = function(winid)
  if not api.nvim_win_is_valid(winid) then return "" end

  local bufnr = api.nvim_win_get_buf(winid)
  local cache = get_window_cache(winid)
  local C = create_components(winid, bufnr)

  -- left: mode + git
  local left_segments = { C.mode() }
  local git_branch = C.git_branch()
  if git_branch ~= "" then left_segments[#left_segments + 1] = git_branch end
  local left = table.concat(left_segments, " ")

  -- right components
  local right_list = {}
  local function push(v) if v and v ~= "" then right_list[#right_list + 1] = v end end
  push(C.diagnostics())
  push(C.lsp_status())
  push(C.position())
  push(C.percentage())
  local right = table.concat(right_list, config.separators.section)

  local center = C.file_info()

  local left_width = width_for(cache, left)
  local right_width = width_for(cache, right)
  local center_w = cache.widths.file_info or width_for(cache, center)
  local window_width = api.nvim_win_get_width(winid)

  if (window_width - (left_width + right_width)) >= center_w + 4 then
    local gap = math.max(1, math.floor((window_width - center_w) / 2) - left_width)
    return left .. string.rep(" ", gap) .. center .. "%=" .. right
  end
  return left .. " " .. center .. "%=" .. right
end

-- Legacy functions for compatibility
M.simple_statusline = function()
  local winid = api.nvim_get_current_win()
  return M.simple_statusline_for_window(winid)
end

M.statusline = function()
  local winid = api.nvim_get_current_win()
  return M.statusline_for_window(winid)
end

-- Throttled cursor update per window
local last_cursor_update = {}
local function cursor_update()
  local winid = api.nvim_get_current_win()
  local now = loop.hrtime() / 1e6
  local last = last_cursor_update[winid] or 0

  if now - last > config.throttle_ms then
    last_cursor_update[winid] = now
    local cache = get_window_cache(winid)
    cache:invalidate({ "position", "percentage" })
    vim.schedule(function()
      if api.nvim_win_is_valid(winid) then
        M.refresh_window(winid)
      end
    end)
  end
end

M.init = function()
  local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

  api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function()
      local winid = api.nvim_get_current_win()
      local cache = get_window_cache(winid)
      cache:invalidate("mode")
      M.refresh_window(winid)
    end
  })

  api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
    group = group,
    callback = function()
      -- Clear git cache for all windows
      window_git_cache = {}
      for winid, cache in pairs(window_caches) do
        cache:invalidate("git_branch")
        if api.nvim_win_is_valid(winid) then
          M.refresh_window(winid)
        end
      end
    end,
  })

  api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
      local winid = api.nvim_get_current_win()
      local cache = get_window_cache(winid)
      cache:invalidate({ "git_branch", "file_info", "lsp_status", "diagnostics", "simple_title" })
      M.refresh_window(winid)
    end
  })

  api.nvim_create_autocmd("DiagnosticChanged", {
    group = group,
    callback = function(ev)
      -- Find windows displaying this buffer and update only those
      local buf = ev.buf
      for _, winid in ipairs(api.nvim_list_wins()) do
        if api.nvim_win_get_buf(winid) == buf then
          local cache = get_window_cache(winid)
          cache:invalidate("diagnostics")
          M.refresh_window(winid)
        end
      end
    end
  })

  api.nvim_create_autocmd({ "CursorMoved" }, {
    group = group,
    callback = cursor_update
  })

  api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = group,
    callback = function(ev)
      local buf = ev.buf
      -- Update all windows showing this buffer
      for _, winid in ipairs(api.nvim_list_wins()) do
        if api.nvim_win_get_buf(winid) == buf then
          local cache = get_window_cache(winid)
          cache:invalidate("lsp_status")
          M.refresh_window(winid)
        end
      end
    end
  })

  api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = group,
    callback = function()
      vim.defer_fn(function() vim.cmd("redrawstatus") end, 10)
    end
  })

  api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
    group = group,
    callback = function()
      local winid = api.nvim_get_current_win()
      M.refresh_window(winid)
    end
  })

  api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(ev)
      local winid = tonumber(ev.match)
      if winid then
        cleanup_window_cache(winid)
        -- Clean up cursor update tracking
        last_cursor_update[winid] = nil
      end
    end
  })
end

M.init()

return M
