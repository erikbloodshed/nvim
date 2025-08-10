local api, fn, loop = vim.api, vim.fn, vim.loop
local M, config, cache = {}, {}, { data = {}, ts = {}, widths = {} }

-- Defaults
config = {
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
    buftypes = { "terminal", "quickfix", "help", "nofile", "prompt" },
    filetypes = { "neo-tree", "lazy", "lspinfo", "checkhealth", "help", "man", "qf", },
    floating_windows = true,
    small_windows = { min_height = 3, min_width = 20 },
  },
}

-- Modes
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

-- Cache utils
local ttl = {
  mode = 50,
  file_info = 200,
  position = 100,
  percentage = 100,
  git_branch = 60000,
  diagnostics = 1000,
  lsp_status = 2000,
  encoding = 120000,
}

local function valid(k)
  return cache.data[k] and cache.ts[k] and (loop.hrtime() / 1e6 - cache.ts[k]) < (ttl[k] or 1000)
end

local function update(k, v)
  cache.data[k], cache.ts[k], cache.widths[k] = v, loop.hrtime() / 1e6, M.width(v)
end

local function get_or_set(k, fnc)
  if valid(k) then
    return cache.data[k]
  end
  local v = fnc()
  update(k, v)
  return v
end

local function invalidate(keys)
  for _, k in ipairs(type(keys) == "string" and { keys } or keys) do
    cache.data[k], cache.ts[k], cache.widths[k] = nil, nil, nil
  end
end

-- Helpers
M.width = function (s)
  return fn.strdisplaywidth(s:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", ""))
end

local function hl(name, text)
  return ("%%#%s#%s%%*"):format(name, text)
end

local loaded = {}

local function require_lazy(mod)
  if not loaded[mod] then
    local ok, res = pcall(require, mod)
    loaded[mod] = ok and res or false
  end
  return loaded[mod]
end

-- Components
local comp = {}

comp.mode = function ()
  return get_or_set("mode", function ()
    local m = modes[api.nvim_get_mode().mode] or { "UNKNOWN", "StatusLineNormal" }
    return hl(m[2], " " .. m[1] .. " ")
  end)
end

comp.file_info = function ()
  return get_or_set("file_info", function ()
    local filename = fn.expand("%:t")
    if filename == "" then filename = "[No Name]" end

    -- Async load file icon if not cached yet
    if cache.data.file_icon == nil then
      cache.data.file_icon = " "
      vim.schedule(function ()
        local devicons = require_lazy("nvim-web-devicons")
        if devicons then
          local icon = devicons.get_icon(filename, fn.expand("%:e"), { default = true }) or ""
          cache.data.file_icon = (icon ~= "" and icon .. " ") or ""
          invalidate("file_info")
          M.refresh(api.nvim_get_current_win())
        end
      end)
    end

    -- Build statusline components
    local components = {}
    if vim.bo.readonly then
      components[#components + 1] = hl("StatusLineReadonly", config.icons.readonly)
    end
    components[#components + 1] = hl(
      vim.bo.modified and "StatusLineModified" or "StatusLineFile",
      (cache.data.file_icon or "") .. filename ..
      (vim.bo.modified and " " .. config.icons.modified or "")
    )

    return table.concat(components, " ")
  end)
end

local git_cache, git_job = {}, nil

comp.git_branch = function ()
  return get_or_set("git_branch", function ()
    local root = cache.data.git_root
      or vim.fs.dirname(vim.fs.find(".git", { upward = true })[1] or "")
    cache.data.git_root = cache.data.git_root or root

    if root == "" then
      return ""
    end
    if git_cache[root] then
      return git_cache[root]
    end
    if git_job then
      return ""
    end

    git_job = true
    vim.schedule(function ()
      if not vim.system then
        git_job = nil
        return
      end
      vim.system(
        { "git", "branch", "--show-current" },
        { cwd = root, text = true },
        vim.schedule_wrap(function (o)
          git_job = nil
          local res = ""
          if o.code == 0 and o.stdout ~= "" then
            local b = o.stdout:gsub("[\n\r]", "")
            if b ~= "" then
              res = hl("StatusLineGit", config.icons.git .. " " .. b)
            end
          end
          git_cache[root] = res
          invalidate("git_branch")
          M.refresh(api.nvim_get_current_win())
        end)
      )
    end)

    return ""
  end)
end

comp.diagnostics = function ()
  return get_or_set("diagnostics", function ()
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
      local count = counts[v[1]]
      if count then
        p[#p + 1] = hl(v[2], v[3] .. " " .. count)
      end
    end
    return table.concat(p, " ")
  end)
end

comp.lsp_status = function ()
  return get_or_set("lsp_status", function ()
    local cl = vim.lsp.get_clients({ bufnr = 0 })
    if #cl == 0 then
      return ""
    end
    local names = {}
    for _, c in ipairs(cl) do
      names[#names + 1] = c.name
    end
    return hl("StatusLineLSP", config.icons.lsp .. " " .. table.concat(names, ", "))
  end)
end

comp.position = function ()
  return get_or_set("position", function ()
    local pos = api.nvim_win_get_cursor(0)
    return hl("StatusLineInfo", ("Ln %d, Col %d"):format(pos[1], pos[2] + 1))
  end)
end

comp.percentage = function ()
  return get_or_set("percentage", function ()
    local curr, total = api.nvim_win_get_cursor(0)[1], api.nvim_buf_line_count(0)
    local pct = total > 0 and math.floor(curr / total * 100) or 0
    return hl("StatusLineInfo", pct .. "%%")
  end)
end

-- Statusline builder
M.statusline = function ()
  local win, left, git, right, names = api.nvim_get_current_win(), { comp.mode() }, comp.git_branch(), {}, {}
  if git ~= "" then
    left[#left + 1] = git
  end
  local function add_right(name, val)
    if val ~= "" then
      right[#right + 1], names[#names + 1] = val, name
    end
  end
  add_right("diagnostics", comp.diagnostics())
  add_right("lsp_status", comp.lsp_status())
  add_right("position", comp.position())
  add_right("percentage", comp.percentage())
  local center = comp.file_info()
  local lw = (cache.widths.mode or M.width(left[1])) + (#git > 0 and (cache.widths.git_branch or M.width(git)) or 0)
  local rw = 0
  for i, p in ipairs(right) do
    rw = rw + (cache.widths[names[i]] or M.width(p))
  end
  if #right > 1 then
    rw = rw + (#right - 1) * M.width(config.separators.section)
  end
  local cw, ww = cache.widths.file_info or M.width(center), api.nvim_win_get_width(win)
  if ww - (lw + rw) >= cw + 4 then
    return table.concat(left, " ")
      .. string.rep(" ", math.max(1, math.floor((ww - cw) / 2) - lw))
      .. center
      .. "%="
      .. table.concat(right, config.separators.section)
  end
  return table.concat(left, " ") .. " " .. center .. "%=" .. table.concat(right, config.separators.section)
end

local function show(win)
  if not api.nvim_win_is_valid(win) then
    return false
  end
  if config.exclude.floating_windows and api.nvim_win_get_config(win).relative ~= "" then
    return false
  end
  local buf = api.nvim_win_get_buf(win)
  if config.exclude.buftypes[vim.api.nvim_get_option_value("buftype", { buf = buf })] then
    return false
  end
  if config.exclude.filetypes[vim.api.nvim_get_option_value("filetype", { buf = buf })] then
    return false
  end
  local sz = config.exclude.small_windows
  return not (api.nvim_win_get_height(win) < sz.min_height or api.nvim_win_get_width(win) < sz.min_width)
end

local expr = '%!v:lua.require("custom_ui.statusline").statusline()'

local function refresh(win)
  api.nvim_set_option_value("statusline", show(win) and expr or "", { win = win })
end

M.refresh = function (win)
  if win then
    refresh(win)
  else
    for _, w in ipairs(api.nvim_list_wins()) do
      refresh(w)
    end
  end
end

-- Throttle
local last = 0
local function cursor_update()
  local now = loop.hrtime() / 1e6
  if now - last > config.throttle_ms then
    last = now
    invalidate({ "position", "percentage" })
    vim.schedule(function ()
      M.refresh(api.nvim_get_current_win())
    end)
  end
end

local g = api.nvim_create_augroup("CustomStatusline", { clear = true })

api.nvim_create_autocmd("ModeChanged", {
  group = g,
  callback = function ()
    invalidate("mode")
    vim.schedule(function ()
      M.refresh(api.nvim_get_current_win())
    end)
  end,
})

-- On major context switches, clear the git cache to prevent memory leaks.
api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
  group = g,
  callback = function ()
    git_cache = {}              -- Clear the unbounded git branch cache
    cache.data.git_root = nil   -- Invalidate the cached git root path
    invalidate("git_branch")
    vim.schedule(function ()
      M.refresh(api.nvim_get_current_win())
    end)
  end,
})

-- On buffer switches, just invalidate the component to allow for an update.
api.nvim_create_autocmd({ "BufEnter" }, {
  group = g,
  callback = function ()
    invalidate("git_branch")
    vim.schedule(function ()
      M.refresh(api.nvim_get_current_win())
    end)
  end,
})

api.nvim_create_autocmd("DiagnosticChanged", {
  group = g,
  callback = function ()
    invalidate("diagnostics")
    vim.schedule(function ()
      M.refresh(api.nvim_get_current_win())
    end)
  end,
})

api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, { group = g, callback = cursor_update })

api.nvim_create_autocmd({ "FocusGained", "DirChanged", "BufEnter" }, {
  group = g,
  callback = function ()
    invalidate("git_branch")
    vim.schedule(function ()
      M.refresh(api.nvim_get_current_win())
    end)
  end,
})

api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
  group = g,
  callback = function ()
    vim.schedule(function ()
      vim.cmd("redrawstatus")
    end)
  end,
})

api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "WinClosed" }, {
  group = g,
  callback = function ()
    M.refresh()
  end,
})

return M
