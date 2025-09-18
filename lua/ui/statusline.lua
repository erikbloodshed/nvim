local api, fn, loop = vim.api, vim.fn, vim.loop
local icons = require("ui.icons")
local M = {}

local function debounce(func, delay)
  local timer = nil
  return function(...)
    local args = { ... }
    if timer then
      timer:stop()
      timer:close()
    end
    timer = vim.defer_fn(function()
      func(unpack(args))
      timer = nil
    end, delay)
  end
end

local Cache = {}
function Cache.new()
  return { data = {}, ts = {} }
end

function Cache.get(cache, key, ttl, generator)
  local now = loop.hrtime() / 1e6
  local entry = cache.data[key]

  if entry and (now - cache.ts[key]) < ttl then
    return entry
  end

  local ok, value = pcall(generator)
  if ok then
    cache.data[key] = value
    cache.ts[key] = now
    return value
  end
  return ""
end

function Cache.invalidate(cache, keys)
  if type(keys) == "string" then keys = { keys } end
  for _, key in ipairs(keys or {}) do
    cache.data[key] = nil
    cache.ts[key] = nil
  end
end

local window_caches = {}
local git_cache = {}
local file_icon_cache = {}

local function get_cache(winid)
  if not window_caches[winid] then
    window_caches[winid] = Cache.new()
  end
  return window_caches[winid]
end

local function cleanup_cache(winid)
  window_caches[winid] = nil
  git_cache[winid] = nil
  file_icon_cache[winid] = nil
end

local config = {
  separators = { left = "", right = "", section = " • " },
  icons = {
    modified = icons.modified,
    readonly = icons.readonly,
    git = icons.git,
    lsp = icons.lsp,
    error = icons.error,
    warn = icons.warn,
    info = icons.info,
    hint = icons.hint,
  },
  exclude = {
    buftypes = { terminal = true, prompt = true },
    filetypes = {
      ["neo-tree"] = true,
      NvimTree = true,
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

local function safe_require(mod)
  local ok, res = pcall(require, mod)
  return ok and res or false
end

-- Debounced refresh functions
local refresh_window_debounced = debounce(function(winid)
  if not api.nvim_win_is_valid(winid) then
    cleanup_cache(winid)
    return
  end

  local is_excluded = false
  if api.nvim_win_is_valid(winid) then
    local buf = api.nvim_win_get_buf(winid)
    local bt = api.nvim_get_option_value("buftype", { buf = buf })
    local ft = api.nvim_get_option_value("filetype", { buf = buf })
    is_excluded = config.exclude.buftypes[bt] or config.exclude.filetypes[ft]
  end

  local expr = string.format(
    '%%!v:lua.require("ui.statusline").%s(%d)',
    is_excluded and "simple_statusline_for_window" or "statusline_for_window",
    winid
  )
  vim.wo[winid].statusline = expr
end, 50)

local refresh_git_debounced = debounce(function()
  git_cache = {}
  for winid in pairs(window_caches) do
    if api.nvim_win_is_valid(winid) then
      local cache = get_cache(winid)
      Cache.invalidate(cache, "git_branch")
      refresh_window_debounced(winid)
    end
  end
end, 100)

-- Component generators
local function create_components(winid, bufnr)
  local cache = get_cache(winid)
  local C = {}

  C.mode = function()
    return Cache.get(cache, "mode", 50, function()
      local m = modes[(api.nvim_get_mode() or {}).mode] or { " ? ", "StatusLineNormal" }
      return hl(m[2], m[1])
    end)
  end

  C.file_info = function()
    return Cache.get(cache, "file_info", 200, function()
      local name = api.nvim_buf_get_name(bufnr)
      name = name == "" and "[No Name]" or fn.fnamemodify(name, ":t")

      -- Get file icon (simplified)
      local icon = ""
      local cache_key = name
      if not file_icon_cache[cache_key] then
        local devicons = safe_require("nvim-web-devicons")
        if devicons and devicons.has_loaded then
          local ic, hl_group = devicons.get_icon(name, fn.fnamemodify(name, ":e"))
          if ic then
            icon = hl_group and hl(hl_group, ic) .. " " or ic .. " "
          end
        end
        file_icon_cache[cache_key] = icon
      else
        icon = file_icon_cache[cache_key]
      end

      local parts = {}
      local readonly = api.nvim_get_option_value("readonly", { buf = bufnr })
      local modified = api.nvim_get_option_value("modified", { buf = bufnr })

      if readonly then
        table.insert(parts, hl("StatusLineReadonly", config.icons.readonly .. " "))
      end

      table.insert(parts, hl(
        modified and "StatusLineModified" or "StatusLineFile",
        icon .. name
      ))

      if modified then
        table.insert(parts, hl("StatusLineModified", " " .. config.icons.modified))
      end

      return table.concat(parts)
    end)
  end

  C.simple_title = function()
    return Cache.get(cache, "simple_title", 3000, function()
      local bt = api.nvim_get_option_value("buftype", { buf = bufnr })
      local ft = api.nvim_get_option_value("filetype", { buf = bufnr })

      local titles = {
        buftype = {
          terminal = icons.terminal .. " Terminal",
          popup = icons.dock .. " Popup",
        },
        filetype = {
          lazy = icons.sleep .. " Lazy",
          ["neo-tree"] = icons.file_tree .. " File Explorer",
          NvimTree = icons.file_tree .. " Files Explorer",
          lspinfo = icons.info .. " LSP Info",
          checkhealth = icons.status .. " Health",
          man = icons.book .. " Manual",
          qf = icons.fix .. " Quickfix",
          help = icons.help .. " Help",
        },
      }

      local title = titles.buftype[bt] or titles.filetype[ft] or "No File"
      return hl("String", title)
    end)
  end

  C.git_branch = function()
    return Cache.get(cache, "git_branch", 60000, function()
      local buf_name = api.nvim_buf_get_name(bufnr)
      local buf_dir = buf_name ~= "" and fn.fnamemodify(buf_name, ":h") or fn.getcwd()

      if not git_cache[buf_dir] then
        local gitdir = vim.fs.find({ ".git" }, { upward = true, path = buf_dir })
        if gitdir and gitdir[1] then
          local root = vim.fs.dirname(gitdir[1])

          vim.system(
            { "git", "symbolic-ref", "--short", "HEAD" },
            { cwd = root, text = true, timeout = 2000 },
            vim.schedule_wrap(function(result)
              if result.code == 0 and result.stdout then
                local branch = result.stdout:gsub("%s*$", "")
                git_cache[buf_dir] = branch ~= "" and
                  hl("StatusLineGit", config.icons.git .. " " .. branch) or ""

                Cache.invalidate(cache, "git_branch")
                refresh_window_debounced(winid)
              end
            end)
          )
        end
        git_cache[buf_dir] = ""
      end

      return git_cache[buf_dir] or ""
    end)
  end

  C.directory = function()
    return Cache.get(cache, "directory", 60000, function()
      local name = api.nvim_buf_get_name(bufnr)
      local dir_path = name == "" and fn.getcwd() or vim.fs.dirname(name)
      local display_name = fn.fnamemodify(dir_path, ":~")

      if display_name and display_name ~= "" and display_name ~= "." then
        return hl("StatusLineDirectory", icons.folder .. " " .. display_name)
      end
      return ""
    end)
  end

  local severities = {
    { vim.diagnostic.severity.ERROR, "StatusLineDiagError", config.icons.error },
    { vim.diagnostic.severity.WARN, "StatusLineDiagWarn", config.icons.warn },
    { vim.diagnostic.severity.INFO, "StatusLineDiagInfo", config.icons.info },
    { vim.diagnostic.severity.HINT, "StatusLineDiagHint", config.icons.hint },
  }

  C.diagnostics = function()
    return Cache.get(cache, "diagnostics", 500, function()
      local counts = vim.diagnostic.count(bufnr)

      local parts = {}
      for _, sev in ipairs(severities) do
        local count = counts[sev[1]]
        if count and count > 0 then
          parts[#parts + 1] = hl(sev[2], sev[3] .. " " .. count)
        end
      end
      return table.concat(parts, " ")
    end)
  end

  C.lsp_status = function()
    return Cache.get(cache, "lsp_status", 2000, function()
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      if #clients == 0 then return "" end

      local names = {}
      for _, client in ipairs(clients) do
        table.insert(names, client.name)
      end
      return hl("StatusLineLsp", config.icons.lsp .. " " .. table.concat(names, ", "))
    end)
  end

  C.position = function()
    return Cache.get(cache, "position", 100, function()
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
    return Cache.get(cache, "percentage", 100, function()
      if not api.nvim_win_is_valid(winid) then return "" end
      local cur = api.nvim_win_get_cursor(winid)[1]
      local total = api.nvim_buf_line_count(bufnr)

      if total <= 1 then return hl("StatusLineValue", "All") end

      local pct = math.floor((cur - 1) / (total - 1) * 100)
      local display = pct <= 5 and "Top" or pct >= 95 and "Bot" or
        (pct >= 45 and pct <= 55) and "Mid" or pct .. "%%"

      return hl("StatusLineValue", display)
    end)
  end

  return C
end

local function display_width(str)
  return fn.strdisplaywidth(str:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", ""))
end

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
  local C = create_components(winid, bufnr)

  local left_parts = { C.mode() }
  local directory = C.directory()
  if directory ~= "" then table.insert(left_parts, directory) end
  local git_branch = C.git_branch()
  if git_branch ~= "" then table.insert(left_parts, git_branch) end
  local left = table.concat(left_parts, " ")

  local right_parts = {}
  for _, component in ipairs({ C.diagnostics(), C.lsp_status(), C.position(), C.percentage() }) do
    if component ~= "" then table.insert(right_parts, component) end
  end
  local right = table.concat(right_parts, hl("StatusLineSeparator", config.separators.section))

  local center = C.file_info()

  local window_width = api.nvim_win_get_width(winid)
  local left_width = display_width(left)
  local right_width = display_width(right)
  local center_width = display_width(center)

  if (window_width - (left_width + right_width)) >= center_width + 4 then
    local gap = math.max(1, math.floor((window_width - center_width) / 2) - left_width)
    return left .. string.rep(" ", gap) .. center .. "%=" .. right
  end

  return left .. " " .. center .. "%=" .. right
end

local cursor_debounced = debounce(function()
  local winid = api.nvim_get_current_win()
  local cache = get_cache(winid)
  Cache.invalidate(cache, { "position", "percentage" })
  refresh_window_debounced(winid)
end, 50)

M.refresh = function(win)
  if win then
    refresh_window_debounced(win)
  else
    for _, w in ipairs(api.nvim_list_wins()) do
      refresh_window_debounced(w)
    end
  end
end

local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

api.nvim_create_autocmd("ModeChanged", {
  group = group,
  callback = function()
    local winid = api.nvim_get_current_win()
    local cache = get_cache(winid)
    Cache.invalidate(cache, "mode")
    refresh_window_debounced(winid)
  end
})

api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
  group = group,
  callback = refresh_git_debounced
})

api.nvim_create_autocmd("BufEnter", {
  group = group,
  callback = function()
    local winid = api.nvim_get_current_win()
    local cache = get_cache(winid)
    Cache.invalidate(cache, { "git_branch", "file_info", "directory", "lsp_status", "diagnostics", "simple_title" })
    refresh_window_debounced(winid)
  end
})

api.nvim_create_autocmd("DiagnosticChanged", {
  group = group,
  callback = function(ev)
    for _, winid in ipairs(api.nvim_list_wins()) do
      if api.nvim_win_get_buf(winid) == ev.buf then
        local cache = get_cache(winid)
        Cache.invalidate(cache, "diagnostics")
        refresh_window_debounced(winid)
      end
    end
  end
})

api.nvim_create_autocmd("CursorMoved", {
  group = group,
  callback = cursor_debounced
})

api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
  group = group,
  callback = function(ev)
    for _, winid in ipairs(api.nvim_list_wins()) do
      if api.nvim_win_get_buf(winid) == ev.buf then
        local cache = get_cache(winid)
        Cache.invalidate(cache, "lsp_status")
        refresh_window_debounced(winid)
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
    refresh_window_debounced(api.nvim_get_current_win())
  end
})

api.nvim_create_autocmd("WinClosed", {
  group = group,
  callback = function(ev)
    local winid = tonumber(ev.match)
    if winid then cleanup_cache(winid) end
  end
})

return M
