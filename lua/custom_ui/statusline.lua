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
    lsp = "",
  },
  center_filename = true,
  enable_profiling = false,
  throttle_ms = 50,
  exclude = {
    buftypes = { terminal = 1, quickfix = 1, help = 1, nofile = 1, prompt = 1 },
    filetypes = {
      NvimTree = 1,
      ["neo-tree"] = 1,
      aerial = 1,
      Outline = 1,
      packer = 1,
      alpha = 1,
      starter = 1,
      TelescopePrompt = 1,
      TelescopeResults = 1,
      TelescopePreview = 1,
      lazy = 1,
      mason = 1,
      lspinfo = 1,
      ["null-ls-info"] = 1,
      checkhealth = 1,
      help = 1,
      man = 1,
      qf = 1,
      fugitive = 1,
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

-- Profiling wrapper
local function prof(name, fn)
  if not config.enable_profiling then
    return fn
  end
  return function(...)
    local st = vim.loop.hrtime()
    local r = fn(...)
    local e = (vim.loop.hrtime() - st) / 1e6
    profile.times[name] = (profile.times[name] or 0) + e
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
local function valid(k, force)
  if force or not cache.data[k] or not cache.ts[k] then
    return false
  end
  return (vim.loop.hrtime() / 1e6 - cache.ts[k]) < (ttl[k] or 1000)
end
local function update(k, v)
  cache.data[k] = v
  cache.ts[k] = vim.loop.hrtime() / 1e6
  cache.widths[k] = M.width(v)
end
local function get_or_set(k, fn)
  if valid(k) then
    return cache.data[k]
  end
  local v = fn()
  update(k, v)
  return v
end
local function invalidate(keys)
  if type(keys) == "string" then
    keys = { keys }
  end
  for _, k in ipairs(keys) do
    cache.data[k] = nil
    cache.ts[k] = nil
    cache.widths[k] = nil
  end
end

-- Helpers
M.width = function(s)
  return vim.fn.strdisplaywidth(s:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", ""))
end
local deps = {
  file_info = function()
    return pcall(require, "nvim-web-devicons")
  end,
  diagnostics = function()
    return vim.diagnostic ~= nil
  end,
  lsp_status = function()
    return vim.lsp ~= nil
  end,
}
local function has(comp)
  return config.components[comp] and (not deps[comp] or deps[comp]())
end

-- Components
local comp = {}
comp.mode = prof("mode", function()
  return get_or_set("mode", function()
    if not has("mode") then
      return ""
    end
    local m = modes[vim.api.nvim_get_mode().mode] or { "UNKNOWN", "StatusLineNormal" }
    return ("%%#%s# %s %%*"):format(m[2], m[1])
  end)
end)
comp.file_info = prof("file_info", function()
  return get_or_set("file_info", function()
    if not has("file_info") then
      return ""
    end
    local fn = vim.fn.expand("%:t")
    if fn == "" then
      fn = "[No Name]"
    end
    local icon = cache.data.file_icon or ""
    if icon == "" then
      local ok, dev = pcall(require, "nvim-web-devicons")
      if ok then
        icon = dev.get_icon(fn, vim.fn.expand("%:e"), { default = true }) or ""
        if icon ~= "" then
          icon = icon .. " "
          cache.data.file_icon = icon
        end
      end
    end
    local parts = {}
    if vim.bo.readonly then
      parts[#parts + 1] = ("%%#StatusLineReadonly#%s%%*"):format(config.icons.readonly)
    end
    parts[#parts + 1] = ("%%#StatusLine%s#%s%s%s%%*"):format(
      vim.bo.modified and "Modified" or "File",
      icon,
      fn,
      vim.bo.modified and " " .. config.icons.modified or ""
    )
    return table.concat(parts, " ")
  end)
end)

-- Git branch (cached per repo)
local git_cache, git_job = {}, nil
comp.git_branch = prof("git_branch", function()
  return get_or_set("git_branch", function()
    if not has("git_branch") then
      return ""
    end
    local root = vim.fs.dirname(vim.fs.find(".git", { upward = true })[1] or "") or ""
    if root == "" then
      return ""
    end
    if git_cache[root] then
      return git_cache[root]
    end
    if vim.system then
      if git_job and git_job.kill then
        git_job:kill()
      end
      git_job = vim.system(
        { "git", "branch", "--show-current" },
        { cwd = root, text = true },
        vim.schedule_wrap(function(o)
          git_job = nil
          local res = ""
          if o.code == 0 and o.stdout ~= "" then
            local b = o.stdout:gsub("[\n\r]", "")
            if b ~= "" then
              res = ("%%#StatusLineGit#%s %s%%*"):format(config.icons.git, b)
            end
          end
          if git_cache[root] ~= res then
            git_cache[root] = res
            update("git_branch", res)
            vim.schedule(function()
              vim.cmd("redrawstatus")
            end)
          end
        end)
      )
    end
    return git_cache[root] or ""
  end)
end)

comp.diagnostics = prof("diagnostics", function()
  return get_or_set("diagnostics", function()
    if not has("diagnostics") then
      return ""
    end
    local c = { error = 0, warn = 0, info = 0, hint = 0 }
    local s = vim.diagnostic.severity
    for _, d in ipairs(vim.diagnostic.get(0)) do
      if d.severity == s.ERROR then
        c.error = c.error + 1
      elseif d.severity == s.WARN then
        c.warn = c.warn + 1
      elseif d.severity == s.INFO then
        c.info = c.info + 1
      elseif d.severity == s.HINT then
        c.hint = c.hint + 1
      end
    end
    local p = {}
    if c.error > 0 then
      p[#p + 1] = ("%%#StatusLineDiagError#%s %d%%*"):format(config.icons.error, c.error)
    end
    if c.warn > 0 then
      p[#p + 1] = ("%%#StatusLineDiagWarn#%s %d%%*"):format(config.icons.warn, c.warn)
    end
    if c.info > 0 then
      p[#p + 1] = ("%%#StatusLineDiagInfo#%s %d%%*"):format(config.icons.info, c.info)
    end
    if c.hint > 0 then
      p[#p + 1] = ("%%#StatusLineDiagHint#%s %d%%*"):format(config.icons.hint, c.hint)
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
    local n = {}
    for _, c in ipairs(cl) do
      n[#n + 1] = c.name
    end
    return ("%%#StatusLineLSP#%s %s%%*"):format(config.icons.lsp, table.concat(n, ", "))
  end)
end)

comp.encoding = prof("encoding", function()
  return get_or_set("encoding", function()
    if not has("encoding") then
      return ""
    end
    local e = vim.bo.fileencoding
    if e == "" then
      e = vim.o.encoding
    end
    return ("%%#StatusLineInfo#%s%%*"):format(e:upper())
  end)
end)

comp.position = prof("position", function()
  return get_or_set("position", function()
    if not has("position") then
      return ""
    end
    local pos = vim.api.nvim_win_get_cursor(0)
    return ("%%#StatusLineInfo#Ln %d, Col %d%%*"):format(pos[1], pos[2] + 1)
  end)
end)

comp.percentage = prof("percentage", function()
  return get_or_set("percentage", function()
    if not has("percentage") then
      return ""
    end
    local curr = vim.api.nvim_win_get_cursor(0)[1]
    local total = vim.api.nvim_buf_line_count(0)
    local pct = total > 0 and math.floor(curr / total * 100) or 0
    return ("%%#StatusLineInfo#%d%%%%%%*"):format(pct)
  end)
end)

-- Statusline builder
M.statusline = function()
  local win = vim.api.nvim_get_current_win()
  local left = { comp.mode() }
  local git = comp.git_branch()
  if git ~= "" then
    left[#left + 1] = git
  end
  local right, right_names = {}, {}
  local d = comp.diagnostics()
  if d ~= "" then
    right[#right + 1] = d
    right_names[#right_names + 1] = "diagnostics"
  end
  local l = comp.lsp_status()
  if l ~= "" then
    right[#right + 1] = l
    right_names[#right_names + 1] = "lsp_status"
  end
  if config.components.encoding then
    right[#right + 1] = comp.encoding()
    right_names[#right_names + 1] = "encoding"
  end
  right[#right + 1] = comp.position()
  right_names[#right_names + 1] = "position"
  if config.components.percentage then
    right[#right + 1] = comp.percentage()
    right_names[#right_names + 1] = "percentage"
  end
  local center = comp.file_info()

  if config.center_filename then
    local lw = (cache.widths.mode or M.width(left[1])) + (git ~= "" and (cache.widths.git_branch or M.width(git)) or 0)
    local rw = 0
    for i, p in ipairs(right) do
      rw = rw + (cache.widths[right_names[i]] or M.width(p))
    end
    if #right > 1 then
      rw = rw + (#right - 1) * M.width(config.separators.section)
    end
    local cw = cache.widths.file_info or M.width(center)
    local ww = vim.api.nvim_win_get_width(win)
    if ww - (lw + rw) >= cw + 4 then
      local cs = math.floor((ww - cw) / 2)
      local pad = math.max(1, cs - lw)
      return table.concat(left, " ")
        .. string.rep(" ", pad)
        .. center
        .. "%="
        .. table.concat(right, config.separators.section)
    end
  end
  return table.concat(left, " ") .. " " .. center .. "%=" .. table.concat(right, config.separators.section)
end

-- Show/hide
local function show(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  if config.exclude.floating_windows and vim.api.nvim_win_get_config(win).relative ~= "" then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if config.exclude.buftypes[vim.api.nvim_get_option_value("buftype", { buf = buf })] then
    return false
  end
  if config.exclude.filetypes[vim.api.nvim_get_option_value("filetype", { buf = buf })] then
    return false
  end
  if config.exclude.small_windows then
    if
      vim.api.nvim_win_get_height(win) < config.exclude.small_windows.min_height
      or vim.api.nvim_win_get_width(win) < config.exclude.small_windows.min_width
    then
      return false
    end
  end
  return true
end

local expr = '%!v:lua.require("custom_ui.statusline").statusline()'
local function refresh(win)
  vim.wo[win].statusline = show(win) and expr or ""
end
M.refresh = function(win)
  if win then
    refresh(win)
  else
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      refresh(w)
    end
  end
end

-- Throttle
local last = 0
local function cursor_update()
  local now = vim.loop.hrtime() / 1e6
  if now - last > config.throttle_ms then
    last = now
    invalidate({ "position", "percentage" })
    vim.schedule(function()
      M.refresh(vim.api.nvim_get_current_win())
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
    vim.api.nvim_set_hl(0, n, o)
  end
end

-- Setup
function M.setup(user)
  config = vim.tbl_deep_extend("force", config, user or {})
  set_hl()
  local g = vim.api.nvim_create_augroup("CustomStatusline", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = g, callback = set_hl })
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = g,
    callback = function()
      invalidate("mode")
      vim.schedule(function()
        M.refresh(vim.api.nvim_get_current_win())
      end)
    end,
  })
  vim.api.nvim_create_autocmd(
    { "BufEnter", "BufWritePost", "TextChanged", "TextChangedI", "BufModifiedSet", "LspAttach", "LspDetach" },
    {
      group = g,
      callback = function()
        invalidate({ "file_info", "lsp_status" })
        vim.schedule(function()
          M.refresh(vim.api.nvim_get_current_win())
        end)
      end,
    }
  )
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = g,
    callback = function()
      invalidate("diagnostics")
      vim.schedule(function()
        M.refresh(vim.api.nvim_get_current_win())
      end)
    end,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, { group = g, callback = cursor_update })
  vim.api.nvim_create_autocmd({ "FocusGained", "DirChanged", "BufEnter" }, {
    group = g,
    callback = function()
      invalidate("git_branch")
      vim.schedule(function()
        M.refresh(vim.api.nvim_get_current_win())
      end)
    end,
  })
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = g,
    callback = function()
      vim.schedule(function()
        vim.cmd("redrawstatus")
      end)
    end,
  })
  vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "WinNew" }, {
    group = g,
    callback = function()
      vim.schedule(function()
        M.refresh(vim.api.nvim_get_current_win())
      end)
    end,
  })
  vim.api.nvim_create_autocmd({ "TabEnter", "SessionLoadPost" }, {
    group = g,
    callback = function()
      vim.schedule(function()
        M.refresh()
      end)
    end,
  })
end

return M
