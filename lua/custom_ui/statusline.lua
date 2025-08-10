local api, fn, loop = vim.api, vim.fn, vim.loop
local M = {}
local config = {}
local cache = { data = {}, ts = {}, widths = {} }

-- Defaults
config = {
  separators = { left = "", right = "", section = " | " },

  throttle_ms = 50,

  icons = {
    modified = "[+]",
    readonly = "",
    git = "",
    lsp = "",
    error = "",
    warn = "󱈸",
    info = "",
    hint = "",
  },

  exclude = {
    buftypes = {
      terminal = true,
      quickfix = true,
      help = true,
      nofile = true,
      prompt = true
    },
    filetypes = {
      ["neo-tree"] = true,
      lazy = true,
      lspinfo = true,
      checkhealth = true,
      help = true,
      man = true,
      qf = true
    },
    floating_windows = false,
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
  simple_title = 5000, -- Cache simple title for 5 seconds
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
    return hl(m[2], m[1])
  end)
end

comp.file_info = function ()
  return get_or_set("file_info", function ()
    local filename = fn.expand("%:t")
    if filename == "" then
      filename = "[No Name]"
    end

    -- Async load file icon if not cached yet
    if cache.data.file_icon == nil then
      cache.data.file_icon = ""
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
      components[#components + 1] = hl("StatusLineReadonly", config.icons.readonly .. " ")
    end
    components[#components + 1] = hl(
      vim.bo.modified and "StatusLineModified" or "StatusLineFile",
      (cache.data.file_icon or "") .. filename
    )
    if vim.bo.modified then
      components[#components + 1] = hl("StatusLineModified", " " .. config.icons.modified)
    end

    return table.concat(components, "")
  end)
end

-- Simple title component for excluded buftypes
comp.simple_title = function ()
  return get_or_set("simple_title", function ()
    local buftype = vim.bo.buftype
    local filetype = vim.bo.filetype
    local title = ""

    -- Determine title based on buffer type or filetype
    if buftype == "terminal" then
      title = "TERMINAL"
    elseif buftype == "quickfix" then
      title = "QUICKFIX"
    elseif buftype == "help" then
      title = "HELP"
    elseif buftype == "nofile" then
      if filetype == "lazy" then
        title = "LAZY"
      elseif filetype == "neo-tree" then
        title = "NEO-TREE"
      elseif filetype == "lspinfo" then
        title = "LSP INFO"
      elseif filetype == "checkhealth" then
        title = "HEALTH CHECK"
      else
        title = "SCRATCH"
      end
    elseif buftype == "prompt" then
      title = "PROMPT"
    elseif filetype == "man" then
      title = "MANUAL"
    elseif filetype == "qf" then
      title = "QUICKFIX"
    else
      -- Fallback to buffer name or generic title
      local name = fn.expand("%:t")
      title = name ~= "" and name:upper() or "BUFFER"
    end

    return hl("StatusLineFile", title)
  end)
end

local git_cache = {}
local git_jobs = {}

comp.git_branch = function ()
  return get_or_set("git_branch", function ()
    local root = cache.data.git_root or vim.fs.dirname(vim.fs.find(".git", { upward = true })[1] or "")
    cache.data.git_root = cache.data.git_root or root

    if root == "" then
      return ""
    end
    if git_cache[root] then
      return git_cache[root]
    end
    if git_jobs[root] then
      return ""
    end

    git_jobs[root] = true
    vim.schedule(function ()
      if not vim.system then
        git_jobs[root] = nil
        return
      end
      vim.system(
        { "git", "branch", "--show-current" },
        { cwd = root, text = true },
        vim.schedule_wrap(function (o)
          git_jobs[root] = nil
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
      if count and count > 0 then
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
    local line_label = hl("StatusLineLabel", "Ln ")
    local line_value = hl("StatusLineValue", tostring(pos[1]))
    local col_label = hl("StatusLineLabel", ", Col ")
    local col_value = hl("StatusLineValue", tostring(pos[2] + 1))
    return line_label .. line_value .. col_label .. col_value
  end)
end

comp.percentage = function ()
  return get_or_set("percentage", function ()
    local curr, total = api.nvim_win_get_cursor(0)[1], api.nvim_buf_line_count(0)
    local pct = total > 0 and math.floor(curr / total * 100) or 0
    return hl("StatusLineValue", pct .. "%%")
  end)
end

-- Simple statusline for excluded buftypes
M.simple_statusline = function ()
  local win = api.nvim_get_current_win()

  -- Center: simple title
  local center = comp.simple_title()

  -- Right side: position and percentage
  local right_segments = {}
  right_segments[#right_segments + 1] = comp.position()
  right_segments[#right_segments + 1] = comp.percentage()
  local right = table.concat(right_segments, config.separators.section)

  -- Calculate widths
  local center_width = M.width(center)
  local window_width = api.nvim_win_get_width(win)

  -- Build simple statusline with center title and right info
  local left_padding = math.max(1, math.floor((window_width - center_width) / 2))

  return string.rep(" ", left_padding)
    .. center
    .. "%="
    .. right
end

-- Main statusline builder
M.statusline = function ()
  local win = api.nvim_get_current_win()

  -- Left side: mode + git branch (if any)
  local left_segments = { comp.mode() }
  local git_branch = comp.git_branch()
  if git_branch ~= "" then
    left_segments[#left_segments + 1] = git_branch
  end
  local left = table.concat(left_segments, " ")

  -- Right side: diagnostics, lsp status, position, percentage
  local right_segments, right_names = {}, {}
  local function add_right(name, value)
    if value ~= "" then
      right_segments[#right_segments + 1] = value
      right_names[#right_names + 1] = name
    end
  end
  add_right("diagnostics", comp.diagnostics())
  add_right("lsp_status", comp.lsp_status())
  add_right("position", comp.position())
  add_right("percentage", comp.percentage())
  local right = table.concat(right_segments, config.separators.section)

  -- Center: file info
  local center = comp.file_info()

  -- Cached widths (fallback to computed width)
  local widths = cache.widths
  local calc_width = M.width
  local left_width = calc_width(left)
  local right_width = calc_width(right)
  local center_width = widths.file_info or calc_width(center)
  local window_width = api.nvim_win_get_width(win)

  -- Build statusline
  if window_width - (left_width + right_width) >= center_width + 4 then
    -- Center fits
    return left
      .. string.rep(" ", math.max(1, math.floor((window_width - center_width) / 2) - left_width))
      .. center
      .. "%="
      .. right
  else
    -- Fallback: no centering
    return left
      .. " "
      .. center
      .. "%="
      .. right
  end
end

local function is_excluded(win)
  if not api.nvim_win_is_valid(win) then
    return true
  end

  -- Check window properties first.
  if config.exclude.floating_windows and api.nvim_win_get_config(win).relative ~= "" then
    return true
  end

  local sz = config.exclude.small_windows
  if api.nvim_win_get_height(win) < sz.min_height or api.nvim_win_get_width(win) < sz.min_width then
    return true
  end

  -- Now, check buffer-related properties.
  local buf = api.nvim_win_get_buf(win)
  local buftype = api.nvim_get_option_value("buftype", { buf = buf })
  local filetype = api.nvim_get_option_value("filetype", { buf = buf })

  -- Check if buffer type or filetype is excluded
  return config.exclude.buftypes[buftype] or config.exclude.filetypes[filetype]
end

local function show(win)
  if not api.nvim_win_is_valid(win) then
    return false
  end

  -- Check window properties first.
  if config.exclude.floating_windows and api.nvim_win_get_config(win).relative ~= "" then
    return false
  end

  local sz = config.exclude.small_windows
  if api.nvim_win_get_height(win) < sz.min_height or api.nvim_win_get_width(win) < sz.min_width then
    return false
  end

  -- Always show statusline, but it will be different for excluded types
  return true
end

local main_expr = '%!v:lua.require("custom_ui.statusline").statusline()'
local simple_expr = '%!v:lua.require("custom_ui.statusline").simple_statusline()'

local function refresh(win)
  local should_show = show(win)
  if should_show then
    local expr = is_excluded(win) and simple_expr or main_expr
    api.nvim_set_option_value("statusline", expr, { win = win })
  else
    api.nvim_set_option_value("statusline", "", { win = win })
  end
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
local cursor_update = function ()
  local now = loop.hrtime() / 1e6
  if now - last > config.throttle_ms then
    last = now
    invalidate({ "position", "percentage" })
    vim.schedule(function ()
      M.refresh(api.nvim_get_current_win())
    end)
  end
end

M.init = function ()
  local g = api.nvim_create_augroup("CustomStatusline", { clear = true })

  api.nvim_create_autocmd("ModeChanged", {
    group = g,
    callback = function ()
      invalidate("mode")
      M.refresh(api.nvim_get_current_win())
    end,
  })

  api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
    group = g,
    callback = function ()
      git_cache = {}            -- Clear the unbounded git branch cache
      cache.data.git_root = nil -- Invalidate the cached git root path
      invalidate("git_branch")
      M.refresh(api.nvim_get_current_win())
    end,
  })

  api.nvim_create_autocmd("BufEnter", {
    group = g,
    callback = function ()
      invalidate({ "git_branch", "file_info", "lsp_status", "diagnostics", "simple_title" })
      vim.schedule(function ()
        M.refresh(api.nvim_get_current_win())
      end)
    end,
  })

  api.nvim_create_autocmd("DiagnosticChanged", {
    group = g,
    callback = function ()
      invalidate("diagnostics")
      M.refresh(api.nvim_get_current_win())
    end,
  })

  api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, { group = g, callback = cursor_update })

  api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = g,
    callback = function ()
      invalidate("lsp_status")
      M.refresh(api.nvim_get_current_win())
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
end

M.init()

return M
