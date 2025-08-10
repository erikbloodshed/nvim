local api, fn, loop = vim.api, vim.fn, vim.loop
local M, config, cache, profile = {}, {}, { data = {}, ts = {}, widths = {} }, { times = {}, counts = {} }

-- Defaults
config = {
  components = {
    mode = true,
    file_info = true,
    git_branch = true,
    diagnostics = true,
    lsp_status = true,
    encoding = false,
    position = true,
    percentage = true,
  },

  separators = { left = "", right = "", section = " | " },

  icons = {
    modified = "[+]",
    readonly = "",
    git = "",
    error = "",
    warn = "",
    info = "",
    hint = "",
    lsp = "",
  },

  center_filename = true,
  enable_profiling = false,
  throttle_ms = 50,

  async = { file_info = true, git_branch = true },

  exclude = {
    buftypes = { "terminal", "quickfix", "help", "nofile", "prompt" },
    filetypes = {
      "neo-tree",
      "lazy",
      "lspinfo",
      "checkhealth",
      "help",
      "man",
      "qf",
    },
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

-- Profiling
local function prof(name, fnc)
  if not config.enable_profiling then
    return fnc
  end
  return function(...)
    local st = loop.hrtime()
    local r = fnc(...)
    local elapsed = (loop.hrtime() - st) / 1e6
    profile.times[name] = (profile.times[name] or 0) + elapsed
    profile.counts[name] = (profile.counts[name] or 0) + 1
    return r
  end
end

M.get_profile = function()
  return vim.deepcopy(profile)
end

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
M.width = function(s)
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

local function has(comp)
  if not config.components[comp] then
    return false
  end
  if comp == "file_info" then
    return require_lazy("nvim-web-devicons") ~= false
  elseif comp == "diagnostics" then
    return vim.diagnostic ~= nil
  elseif comp == "lsp_status" then
    return vim.lsp ~= nil
  elseif comp == "git_branch" then
    return true
  end
  return true
end

-- Components
local comp = {}

comp.mode = prof("mode", function()
  return get_or_set("mode", function()
    if not has("mode") then
      return ""
    end
    local m = modes[api.nvim_get_mode().mode] or { "UNKNOWN", "StatusLineNormal" }
    return hl(m[2], " " .. m[1] .. " ")
  end)
end)

comp.file_info = prof("file_info", function()
  return get_or_set("file_info", function()
    if not has("file_info") then
      return ""
    end
    local fnm = fn.expand("%:t")
    if fnm == "" then
      fnm = "[No Name]"
    end
    local icon = cache.data.file_icon or ""

    if config.async.file_info and icon == "" then
      cache.data.file_icon = " "
      vim.schedule(function()
        local dev = require_lazy("nvim-web-devicons")
        if dev then
          local ic = dev.get_icon(fnm, fn.expand("%:e"), { default = true }) or ""
          if ic ~= "" then
            ic = ic .. " "
          end
          cache.data.file_icon = ic
          invalidate("file_info")
          M.refresh(api.nvim_get_current_win())
        end
      end)
    elseif icon == "" then
      local dev = require_lazy("nvim-web-devicons")
      if dev then
        icon = dev.get_icon(fnm, fn.expand("%:e"), { default = true }) or ""
        if icon ~= "" then
          icon = icon .. " "
        end
        cache.data.file_icon = icon
      end
    end

    local parts = {}
    if vim.bo.readonly then
      parts[#parts + 1] = hl("StatusLineReadonly", config.icons.readonly)
    end
    parts[#parts + 1] = hl(
      vim.bo.modified and "StatusLineModified" or "StatusLineFile",
      (cache.data.file_icon or "") .. fnm .. (vim.bo.modified and " " .. config.icons.modified or "")
    )
    return table.concat(parts, " ")
  end)
end)

local git_cache, git_job = {}, nil
comp.git_branch = prof("git_branch", function()
  return get_or_set("git_branch", function()
    if not has("git_branch") then
      return ""
    end
    local root = cache.data.git_root or vim.fs.dirname(vim.fs.find(".git", { upward = true })[1] or "")
    if not cache.data.git_root then
      cache.data.git_root = root
    end
    if root == "" then
      return ""
    end
    if git_cache[root] then
      return git_cache[root]
    end

    if config.async.git_branch and not git_job then
      git_job = true
      vim.schedule(function()
        if vim.system then
          vim.system(
            { "git", "branch", "--show-current" },
            { cwd = root, text = true },
            vim.schedule_wrap(function(o)
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
        end
      end)
    end

    return "" -- no branch yet, async will update
  end)
end)

comp.diagnostics = prof("diagnostics", function()
  return get_or_set("diagnostics", function()
    if not has("diagnostics") then
      return ""
    end
    local counts, s = { error = 0, warn = 0, info = 0, hint = 0 }, vim.diagnostic.severity
    for _, d in ipairs(vim.diagnostic.get(0)) do
      if d.severity == s.ERROR then
        counts.error = counts.error + 1
      elseif d.severity == s.WARN then
        counts.warn = counts.warn + 1
      elseif d.severity == s.INFO then
        counts.info = counts.info + 1
      elseif d.severity == s.HINT then
        counts.hint = counts.hint + 1
      end
    end
    local p = {}
    if counts.error > 0 then
      p[#p + 1] = hl("StatusLineDiagError", config.icons.error .. " " .. counts.error)
    end
    if counts.warn > 0 then
      p[#p + 1] = hl("StatusLineDiagWarn", config.icons.warn .. " " .. counts.warn)
    end
    if counts.info > 0 then
      p[#p + 1] = hl("StatusLineDiagInfo", config.icons.info .. " " .. counts.info)
    end
    if counts.hint > 0 then
      p[#p + 1] = hl("StatusLineDiagHint", config.icons.hint .. " " .. counts.hint)
    end
    return table.concat(p, " ")
  end)
end)

comp.lsp_status = prof("lsp_status", function()
  return get_or_set("lsp_status", function()
    if not has("lsp_status") then
      return ""
    end
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
end)

comp.encoding = prof("encoding", function()
  return get_or_set("encoding", function()
    if not has("encoding") then
      return ""
    end
    local e = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
    return hl("StatusLineInfo", e:upper())
  end)
end)

comp.position = prof("position", function()
  return get_or_set("position", function()
    if not has("position") then
      return ""
    end
    local pos = api.nvim_win_get_cursor(0)
    return hl("StatusLineInfo", ("Ln %d, Col %d"):format(pos[1], pos[2] + 1))
  end)
end)

comp.percentage = prof("percentage", function()
  return get_or_set("percentage", function()
    if not has("percentage") then
      return ""
    end
    local curr, total = api.nvim_win_get_cursor(0)[1], api.nvim_buf_line_count(0)
    local pct = total > 0 and math.floor(curr / total * 100) or 0
    return hl("StatusLineInfo", pct .. "%%")
  end)
end)

-- Statusline builder
M.statusline = function()
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
  if config.components.encoding then
    add_right("encoding", comp.encoding())
  end
  add_right("position", comp.position())
  if config.components.percentage then
    add_right("percentage", comp.percentage())
  end
  local center = comp.file_info()
  if config.center_filename then
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
  end
  return table.concat(left, " ") .. " " .. center .. "%=" .. table.concat(right, config.separators.section)
end

-- Show/hide
local function list_to_set(list)
  local set = {}
  for _, v in ipairs(list) do
    set[v] = true
  end
  return set
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
M.refresh = function(win)
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
    vim.schedule(function()
      M.refresh(api.nvim_get_current_win())
    end)
  end
end

-- Highlights
local function set_hl()
  local h = {
    StatusLineNormal = { fg = "#bd93f9", bg = "NONE", bold = true },
    StatusLineInsert = { fg = "#50fa7b", bg = "NONE", bold = true },
    StatusLineVisual = { fg = "#ff79c6", bg = "NONE", bold = true },
    StatusLineCommand = { fg = "#f1fa8c", bg = "NONE", bold = true },
    StatusLineReplace = { fg = "#ffb86c", bg = "NONE", bold = true },
    StatusLineTerminal = { fg = "#8be9fd", bg = "NONE", bold = true },
    StatusLineFile = { fg = "#f8f8f2", bg = "NONE" },
    StatusLineModified = { fg = "#f1fa8c", bg = "NONE", bold = true },
    StatusLineReadonly = { fg = "#6272a4", bg = "NONE" },
    StatusLineGit = { fg = "#ffb86c", bg = "NONE" },
    StatusLineInfo = { fg = "#6272a4", bg = "NONE" },
    StatusLineDiagError = { fg = "#ff5555", bg = "NONE" },
    StatusLineDiagWarn = { fg = "#f1fa8c", bg = "NONE" },
    StatusLineDiagInfo = { fg = "#8be9fd", bg = "NONE" },
    StatusLineDiagHint = { fg = "#50fa7b", bg = "NONE" },
    StatusLineLSP = { fg = "#50fa7b", bg = "NONE" },
  }
  for n, o in pairs(h) do
    api.nvim_set_hl(0, n, o)
  end
end

-- Setup
function M.setup(user)
  config = vim.tbl_deep_extend("force", config, user or {})
  config.exclude.buftypes = list_to_set(config.exclude.buftypes)
  config.exclude.filetypes = list_to_set(config.exclude.filetypes)
  set_hl()
  local g = api.nvim_create_augroup("CustomStatusline", { clear = true })
  api.nvim_create_autocmd("ColorScheme", { group = g, callback = set_hl })
  api.nvim_create_autocmd("ModeChanged", {
    group = g,
    callback = function()
      invalidate("mode")
      vim.schedule(function()
        M.refresh(api.nvim_get_current_win())
      end)
    end,
  })

  -- On major context switches, clear the git cache to prevent memory leaks.
  api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
    group = g,
    callback = function()
      git_cache = {} -- Clear the unbounded git branch cache
      cache.data.git_root = nil -- Invalidate the cached git root path
      invalidate("git_branch")
      vim.schedule(function()
        M.refresh(api.nvim_get_current_win())
      end)
    end,
  })

  -- On buffer switches, just invalidate the component to allow for an update.
  api.nvim_create_autocmd({ "BufEnter" }, {
    group = g,
    callback = function()
      invalidate("git_branch")
      vim.schedule(function()
        M.refresh(api.nvim_get_current_win())
      end)
    end,
  })

  api.nvim_create_autocmd("DiagnosticChanged", {
    group = g,
    callback = function()
      invalidate("diagnostics")
      vim.schedule(function()
        M.refresh(api.nvim_get_current_win())
      end)
    end,
  })

  api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, { group = g, callback = cursor_update })

  api.nvim_create_autocmd({ "FocusGained", "DirChanged", "BufEnter" }, {
    group = g,
    callback = function()
      invalidate("git_branch")
      vim.schedule(function()
        M.refresh(api.nvim_get_current_win())
      end)
    end,
  })

  api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = g,
    callback = function()
      vim.schedule(function()
        vim.cmd("redrawstatus")
      end)
    end,
  })

  api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "WinClosed" }, {
    group = g,
    callback = function()
      M.refresh()
    end,
  })
end

return M
