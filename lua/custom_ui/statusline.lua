local api, fn, loop = vim.api, vim.fn, vim.loop
local M = {}
local config = {}

-- Cache class
local Cache = {}
Cache.__index = Cache

function Cache:new(ttl_map)
  local instance = setmetatable({}, self)
  instance.data = {}
  instance.ts = {}
  instance.widths = {}
  instance.ttl = ttl_map or {}
  return instance
end

function Cache:valid(key)
  return self.data[key] and self.ts[key] and (loop.hrtime() / 1e6 - self.ts[key]) < (self.ttl[key] or 1000)
end

function Cache:update(key, value)
  self.data[key] = value
  self.ts[key] = loop.hrtime() / 1e6
  self.widths[key] = self:width(value)
end

function Cache:get_or_set(key, fnc)
  if self:valid(key) then
    return self.data[key]
  end
  local value = fnc()
  self:update(key, value)
  return value
end

function Cache:invalidate(keys)
  keys = type(keys) == "string" and { keys } or keys
  for _, k in ipairs(keys) do
    self.data[k] = nil
    self.ts[k] = nil
    self.widths[k] = nil
  end
end

function Cache:width(s)
  return fn.strdisplaywidth(s:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", ""))
end

local cache = Cache:new({
  mode = 50,
  file_info = 200,
  position = 100,
  percentage = 100,
  git_branch = 60000,
  diagnostics = 1000,
  lsp_status = 2000,
  encoding = 120000,
  simple_title = 5000, -- Cache simple title for 5 seconds
})

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
    buftypes = {
      terminal = true,
      quickfix = true,
      help = true,
      nofile = true,
      prompt = true,
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

-- Helpers
M.width = function (s)
  return cache:width(s) -- Delegate to cache's width method for consistency
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
  return cache:get_or_set("mode", function ()
    local m = modes[api.nvim_get_mode().mode] or { "UNKNOWN", "StatusLineNormal" }
    return hl(m[2], m[1])
  end)
end

comp.file_info = function ()
  return cache:get_or_set("file_info", function ()
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
          cache:invalidate("file_info")
          M.refresh(api.nvim_get_current_win())
        end
      end)
    end

    -- Build statusline components
    local components = {}
    if vim.bo.readonly then
      components[#components + 1] = hl("StatusLineReadonly", config.icons.readonly .. " ")
    end
    components[#components + 1] =
      hl(vim.bo.modified and "StatusLineModified" or "StatusLineFile", (cache.data.file_icon or "") .. filename)
    if vim.bo.modified then
      components[#components + 1] = hl("StatusLineModified", " " .. config.icons.modified)
    end

    return table.concat(components, "")
  end)
end

-- Simple title component for excluded buftypes
comp.simple_title = function ()
  return cache:get_or_set("simple_title", function ()
    local buftype, filetype = vim.bo.buftype, vim.bo.filetype
    local title_map = {
      buftype = {
        terminal = "TERMINAL",
        quickfix = "QUICKFIX",
        help = "HELP",
        prompt = "PROMPT",
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

    local title = title_map.buftype[buftype]
      or (buftype == "nofile" and title_map.filetype[filetype])
      or title_map.filetype[filetype]

    if not title then
      local name = fn.expand("%:t")
      title = (name ~= "" and name:upper()) or string.format("[%s]", (buftype ~= "" and buftype:upper() or "BUFFER"))
    end

    return hl("StatusLineFile", title or "SCRATCH")
  end)
end

local git_cache = {}
local git_jobs = {}

comp.git_branch = function ()
  return cache:get_or_set("git_branch", function ()
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

      -- Add timeout and better error handling
      ---@diagnostic disable: need-check-nil
      local timer = vim.loop.new_timer()
      local completed = false
      timer:start(5000, 0, function () -- 5 second timeout
        if not completed then
          completed = true
          git_jobs[root] = nil
          timer:close()
        end
      end)

      vim.system(
        { "git", "branch", "--show-current" },
        { cwd = root, text = true, timeout = 3000 },
        vim.schedule_wrap(function (o)
          if completed then
            return
          end
          completed = true
          timer:close()

          git_jobs[root] = nil
          local res = ""

          if o and o.code == 0 and o.stdout and o.stdout ~= "" then
            local b = o.stdout:gsub("[\n\r]", "")
            if b ~= "" then
              res = hl("StatusLineGit", config.icons.git .. " " .. b)
            end
          end

          git_cache[root] = res
          cache:invalidate("git_branch")

          -- Validate window before refresh
          local current_win = api.nvim_get_current_win()
          if api.nvim_win_is_valid(current_win) then
            M.refresh(current_win)
          end
        end)
      )
    end)

    return ""
  end)
end

comp.diagnostics = function ()
  return cache:get_or_set("diagnostics", function ()
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
  return cache:get_or_set("lsp_status", function ()
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
  return cache:get_or_set("position", function ()
    local pos = api.nvim_win_get_cursor(0)
    return table.concat({
      hl("StatusLineLabel", "Ln "),
      hl("StatusLineValue", tostring(pos[1])),
      hl("StatusLineLabel", ", Col "),
      hl("StatusLineValue", tostring(pos[2] + 1)),
    })
  end)
end

comp.percentage = function ()
  return cache:get_or_set("percentage", function ()
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
  local pos_str = comp.position()
  local pct_str = comp.percentage()

  if pos_str ~= "" then
    right_segments[#right_segments + 1] = pos_str
  end
  if pct_str ~= "" then
    right_segments[#right_segments + 1] = pct_str
  end

  local right = table.concat(right_segments, config.separators.section)

  -- Calculate widths
  local center_width = M.width(center)
  local right_width = M.width(right)
  local window_width = api.nvim_win_get_width(win)

  -- Build simple statusline with center title and right info
  if window_width >= center_width + right_width + 4 then
    local left_padding = math.max(1, math.floor((window_width - center_width) / 2))
    return string.rep(" ", left_padding) .. center .. "%=" .. right
  else
    -- Fallback for very narrow windows
    return center .. "%=" .. right
  end
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
    return left .. " " .. center .. "%=" .. right
  end
end

-- Helper functions for determining statusline type
local function should_hide_completely(win)
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

  return false
end

local function is_excluded_buftype(win)
  if not api.nvim_win_is_valid(win) then
    return false
  end

  local buf = api.nvim_win_get_buf(win)
  local buftype = api.nvim_get_option_value("buftype", { buf = buf })
  local filetype = api.nvim_get_option_value("filetype", { buf = buf })

  -- Check if buffer type or filetype is excluded
  return config.exclude.buftypes[buftype] or config.exclude.filetypes[filetype]
end

local main_expr = '%!v:lua.require("custom_ui.statusline").statusline()'
local simple_expr = '%!v:lua.require("custom_ui.statusline").simple_statusline()'

local function refresh(win)
  if should_hide_completely(win) then
    -- Hide statusline completely for very small or floating windows
    api.nvim_set_option_value("statusline", "", { win = win })
  elseif is_excluded_buftype(win) then
    -- Show simple statusline for excluded buffer types
    api.nvim_set_option_value("statusline", simple_expr, { win = win })
  else
    -- Show full statusline for normal buffers
    api.nvim_set_option_value("statusline", main_expr, { win = win })
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
    cache:invalidate({ "position", "percentage" })
    vim.schedule(function ()
      M.refresh(api.nvim_get_current_win())
    end)
  end
end

M.init = function ()
  local group_id = api.nvim_create_augroup("CustomStatusline", { clear = true })

  api.nvim_create_autocmd("ModeChanged", {
    group = group_id,
    callback = function ()
      cache:invalidate("mode")
      M.refresh(api.nvim_get_current_win())
    end,
  })

  api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
    group = group_id,
    callback = function ()
      git_cache = {}            -- Clear the unbounded git branch cache
      cache.data.git_root = nil -- Invalidate the cached git root path
      cache:invalidate("git_branch")
      M.refresh(api.nvim_get_current_win())
    end,
  })

  api.nvim_create_autocmd("BufEnter", {
    group = group_id,
    callback = function ()
      cache:invalidate({ "git_branch", "file_info", "lsp_status", "diagnostics", "simple_title" })
      M.refresh(api.nvim_get_current_win())
    end,
  })

  api.nvim_create_autocmd("DiagnosticChanged", {
    group = group_id,
    callback = function ()
      cache:invalidate("diagnostics")
      M.refresh(api.nvim_get_current_win())
    end,
  })

  api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, { group = group_id, callback = cursor_update })

  api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = group_id,
    callback = function ()
      cache:invalidate("lsp_status")
      M.refresh(api.nvim_get_current_win())
    end,
  })

  api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = group_id,
    callback = function ()
      vim.schedule(function ()
        vim.cmd("redrawstatus")
      end)
    end,
  })

  api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "WinClosed" }, {
    group = group_id,
    callback = function ()
      M.refresh()
    end,
  })
end

M.init()

return M
