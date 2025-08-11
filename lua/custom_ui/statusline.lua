-- Optimized statusline.lua
-- Goals: fewer expensive API calls per render, better cache/invalidation,
-- consolidated async git handling, improved readability and maintainability.

local api, fn, loop = vim.api, vim.fn, vim.loop
local M = {}

-- Lightweight Cache
local Cache = {}
Cache.__index = Cache

function Cache:new(ttl_map)
  return setmetatable({
    data = {},
    ts = {},
    widths = {},
    ttl = ttl_map or {},
  }, self)
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
  -- compute and store width once when value is string
  if type(value) == "string" then
    -- strip statusline highlight markers for width
    local plain = value:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", "")
    self.widths[key] = fn.strdisplaywidth(plain)
  else
    self.widths[key] = nil
  end
end

function Cache:get_or_set(key, fnc)
  if self:valid(key) then
    return self.data[key]
  end
  local ok, v = pcall(fnc)
  if not ok then
    v = ""
  end
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

-- default TTLs tuned for typical usage
local cache = Cache:new({
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

-- config
local config = {
  separators = { left = "", right = "", section = " | " },
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
      terminal = true, quickfix = true, help = true, nofile = true, prompt = true,
    },
    filetypes = {
      ["neo-tree"] = true, lazy = true, lspinfo = true, checkhealth = true, help = true, man = true, qf = true,
    },
    floating_windows = false,
    small_windows = { min_height = 3, min_width = 20 },
  },
}

-- minimal mode mapping
local modes = {
  n = { "NORMAL", "StatusLineNormal" },
  i = { "INSERT", "StatusLineInsert" },
  v = { "VISUAL", "StatusLineVisual" },
  V = { "V-LINE", "StatusLineVisual" },
  ["\22"] = { "V-BLOCK", "StatusLineVisual" },
  c = { "COMMAND", "StatusLineCommand" },
  R = { "REPLACE", "StatusLineReplace" },
  r = { "REPLACE", "StatusLineReplace" },
  s = { "SELECT", "StatusLineVisual" },
  S = { "S-LINE", "StatusLineVisual" },
  ["\19"] = { "S-BLOCK", "StatusLineVisual" },
  t = { "TERMINAL", "StatusLineTerminal" },
}

-- helpers
local function hl(name, text)
  return ("%%#%s#%s%%*"):format(name, text)
end

local loaded = {}
local function require_safe(mod)
  if loaded[mod] ~= nil then
    return loaded[mod]
  end
  local ok, res = pcall(require, mod)
  loaded[mod] = ok and res or false
  return loaded[mod]
end

-- components table
local comp = {}

comp.mode = function()
  return cache:get_or_set("mode", function()
    local m = modes[(api.nvim_get_mode() or {}).mode] or { "UNKNOWN", "StatusLineNormal" }
    return hl(m[2], m[1])
  end)
end

comp.file_info = function()
  return cache:get_or_set("file_info", function()
    local name = fn.expand("%:t")
    if name == "" then name = "[No Name]" end

    -- start icon loading async if needed
    if cache.data.file_icon == nil then
      cache.data.file_icon = ""
      -- defer to allow initial render
      vim.defer_fn(function()
        local devicons = require_safe("nvim-web-devicons")
        if devicons then
          local icon = devicons.get_icon(name, fn.expand("%:e"), { default = true }) or ""
          cache.data.file_icon = (icon ~= "" and (icon .. " ")) or ""
          cache:invalidate("file_info")
          local w = api.nvim_get_current_win()
          if api.nvim_win_is_valid(w) then M.refresh(w) end
        end
      end, 10)
    end

    local comps = {}
    if vim.bo.readonly then
      comps[#comps + 1] = hl("StatusLineReadonly", config.icons.readonly .. " ")
    end
    comps[#comps + 1] = hl(vim.bo.modified and "StatusLineModified" or "StatusLineFile",
      (cache.data.file_icon or "") .. name)
    if vim.bo.modified then comps[#comps + 1] = hl("StatusLineModified", " " .. config.icons.modified) end
    return table.concat(comps, "")
  end)
end

comp.simple_title = function()
  return cache:get_or_set("simple_title", function()
    local bt, ft = vim.bo.buftype, vim.bo.filetype
    local title_map = {
      buftype = {
        terminal = "TERMINAL",
        quickfix = "QUICKFIX",
        help = "HELP",
        prompt = "PROMPT",
        nofile = "NO FILE",
      },
      filetype = {
        lazy = "LAZY",
        ["neo-tree"] = "NEO-TREE",
        lspinfo = "LSP INFO",
        checkhealth = "HEALTH CHECK",
        man = "MANUAL",
        qf = "QUICKFIX",
        help = "HELP",
      },
    }

    -- Prefer explicit buftype mapping, else filetype mapping
    local title = title_map.buftype[bt]
    if not title or title == "NO FILE" then
      title = title_map.filetype[ft] or title
    end

    if not title or title == "NO FILE" then
      local name = fn.expand("%:t")
      title = (name ~= "" and name:upper()) or
        string.format("[%s]", (bt ~= "" and bt:upper() or "BUFFER"))
    end

    return hl("StatusLineFile", title)
  end)
end

-- Git branch: single async caller per repo root
local git_cache = {}
local git_running = {}

local function fetch_git_branch(root)
  if git_running[root] then return end
  git_running[root] = true

  -- use vim.system if available; fallback to jobstart
  local function on_result(branch)
    git_running[root] = nil
    local res = ""
    if branch and branch ~= "" then
      res = hl("StatusLineGit", config.icons.git .. " " .. branch)
    end
    git_cache[root] = res
    cache:invalidate("git_branch")
    local w = api.nvim_get_current_win()
    if api.nvim_win_is_valid(w) then M.refresh(w) end
  end

  if vim.system then
    vim.system({ "git", "branch", "--show-current" }, { cwd = root, text = true, timeout = 3000 }, function(o)
      local branch = ""
      if o and o.code == 0 and o.stdout then
        branch = o.stdout:gsub("[\n\r]", "")
      end
      vim.schedule_wrap(on_result)(branch)
    end)
  else
    -- fallback: jobstart
    local stdout = {}
    local j = vim.fn.jobstart({ "git", "branch", "--show-current" }, {
      on_stdout = function(_, data)
        if data then for _, l in ipairs(data) do if l ~= "" then stdout[#stdout + 1] = l end end end
      end,
      on_exit = function()
        on_result(table.concat(stdout, ""))
      end,
      cwd = root,
    })
    if j <= 0 then
      git_running[root] = nil
      git_cache[root] = ""
    end
  end
end

comp.git_branch = function()
  return cache:get_or_set("git_branch", function()
    local gitdir = vim.fs.find({ ".git" }, { upward = true, path = fn.getcwd() })
    local root = ""
    if gitdir and gitdir[1] then
      root = vim.fs.dirname(gitdir[1])
    end
    cache.data.git_root = cache.data.git_root or root
    if root == "" then return "" end
    if git_cache[root] then return git_cache[root] end
    if not git_running[root] then
      -- schedule fetch (non-blocking)
      vim.defer_fn(function() fetch_git_branch(root) end, 20)
    end
    return ""
  end)
end

comp.diagnostics = function()
  return cache:get_or_set("diagnostics", function()
    local counts = vim.diagnostic.count(0)
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

comp.lsp_status = function()
  return cache:get_or_set("lsp_status", function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if not clients or #clients == 0 then return "" end
    local names = {}
    for _, c in ipairs(clients) do names[#names + 1] = c.name end
    return hl("StatusLineLSP", config.icons.lsp .. " " .. table.concat(names, ", "))
  end)
end

comp.position = function()
  return cache:get_or_set("position", function()
    local pos = api.nvim_win_get_cursor(0)
    return table.concat({ hl("StatusLineLabel", "Ln "), hl("StatusLineValue", tostring(pos[1])), hl("StatusLineLabel",
      ", Col "), hl("StatusLineValue", tostring(pos[2] + 1)) })
  end)
end

comp.percentage = function()
  return cache:get_or_set("percentage", function()
    local cur = api.nvim_win_get_cursor(0)[1]
    local total = api.nvim_buf_line_count(0)
    local pct = total > 0 and math.floor(cur / total * 100) or 0
    return hl("StatusLineValue", tostring(pct) .. "%%")
  end)
end

-- Utility: calculate width prefer cache.widths
local function width_for(key_or_str)
  if cache.widths[key_or_str] then return cache.widths[key_or_str] end
  if type(key_or_str) == "string" then
    local plain = key_or_str:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", "")
    return fn.strdisplaywidth(plain)
  end
  return 0
end

-- Decide when to hide/choose simple statusline
local function should_hide_completely(win)
  if not api.nvim_win_is_valid(win) then return true end
  if config.exclude.floating_windows and api.nvim_win_get_config(win).relative ~= "" then return true end
  local sz = config.exclude.small_windows
  if api.nvim_win_get_height(win) < sz.min_height or api.nvim_win_get_width(win) < sz.min_width then return true end
  return false
end

local function is_excluded_buftype(win)
  if not api.nvim_win_is_valid(win) then return false end
  local buf = api.nvim_win_get_buf(win)
  local bt = api.nvim_get_option_value("buftype", { buf = buf })
  local ft = api.nvim_get_option_value("filetype", { buf = buf })
  return config.exclude.buftypes[bt] or config.exclude.filetypes[ft]
end

-- expressions used by vim
local main_expr = '%!v:lua.require("custom_ui.statusline").statusline()'
local simple_expr = '%!v:lua.require("custom_ui.statusline").simple_statusline()'

-- central refresh to minimize repeated logic
local function set_statusline_for_win(win)
  if should_hide_completely(win) then
    api.nvim_set_option_value("statusline", "", { win = win })
    return
  end
  if is_excluded_buftype(win) then
    api.nvim_set_option_value("statusline", simple_expr, { win = win })
  else
    api.nvim_set_option_value("statusline", main_expr, { win = win })
  end
end

M.refresh = function(win)
  if win then
    if api.nvim_win_is_valid(win) then set_statusline_for_win(win) end
  else
    for _, w in ipairs(api.nvim_list_wins()) do set_statusline_for_win(w) end
  end
end

-- build simple statusline
M.simple_statusline = function()
  local win = api.nvim_get_current_win()
  local center = comp.simple_title()
  local pos = comp.position()
  local pct = comp.percentage()

  local right = table.concat((function()
    local t = {}
    if pos ~= "" then t[#t + 1] = pos end
    if pct ~= "" then t[#t + 1] = pct end
    return t
  end)(), config.separators.section)

  local cw = width_for(center)
  local rw = width_for(right)
  local ww = api.nvim_win_get_width(win)

  if ww >= cw + rw + 4 then
    local left_pad = math.max(1, math.floor((ww - cw) / 2))
    return string.rep(" ", left_pad) .. center .. "%=" .. right
  end
  return center .. "%=" .. right
end

-- main statusline
M.statusline = function()
  local win = api.nvim_get_current_win()
  -- left: mode + git
  local left_segments = { comp.mode() }
  local gb = comp.git_branch()
  if gb ~= "" then left_segments[#left_segments + 1] = gb end
  local left = table.concat(left_segments, " ")

  -- right components
  local right_list = {}
  local function push(v) if v and v ~= "" then right_list[#right_list + 1] = v end end
  push(comp.diagnostics())
  push(comp.lsp_status())
  push(comp.position())
  push(comp.percentage())
  local right = table.concat(right_list, config.separators.section)

  local center = comp.file_info()

  local left_w = width_for(left)
  local right_w = width_for(right)
  local center_w = cache.widths.file_info or width_for(center)
  local ww = api.nvim_win_get_width(win)

  if (ww - (left_w + right_w)) >= center_w + 4 then
    local gap = math.max(1, math.floor((ww - center_w) / 2) - left_w)
    return left .. string.rep(" ", gap) .. center .. "%=" .. right
  end
  return left .. " " .. center .. "%=" .. right
end

-- throttled cursor update
local last = 0
local function cursor_update()
  local now = loop.hrtime() / 1e6
  if now - last > config.throttle_ms then
    last = now
    cache:invalidate({ "position", "percentage" })
    vim.schedule(function() M.refresh(api.nvim_get_current_win()) end)
  end
end

-- setup autocommands
M.init = function()
  local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

  api.nvim_create_autocmd("ModeChanged",
    {
      group = group,
      callback = function()
        cache:invalidate("mode")
        M.refresh(api.nvim_get_current_win())
      end
    })

  api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
    group = group,
    callback = function()
      git_cache = {}
      cache.data.git_root = nil
      cache:invalidate("git_branch")
      M.refresh(api.nvim_get_current_win())
    end,
  })

  api.nvim_create_autocmd("BufEnter",
    {
      group = group,
      callback = function()
        cache:invalidate({ "git_branch", "file_info", "lsp_status", "diagnostics", "simple_title" })
        M.refresh(api.nvim_get_current_win())
      end
    })

  api.nvim_create_autocmd("DiagnosticChanged",
    {
      group = group,
      callback = function()
        cache:invalidate("diagnostics")
        M.refresh(api.nvim_get_current_win())
      end
    })

  api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, { group = group, callback = cursor_update })

  api.nvim_create_autocmd({ "LspAttach", "LspDetach" },
    {
      group = group,
      callback = function()
        cache:invalidate("lsp_status")
        M.refresh(api.nvim_get_current_win())
      end
    })

  api.nvim_create_autocmd({ "VimResized", "WinResized" },
    { group = group, callback = function() vim.defer_fn(function() vim.cmd("redrawstatus") end, 10) end })

  api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "WinClosed" },
    { group = group, callback = function() M.refresh() end })
end

M.init()

return M
