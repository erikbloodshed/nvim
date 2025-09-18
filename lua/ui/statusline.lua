local api, fn, uv = vim.api, vim.fn, vim.uv
local icons = require("ui.icons")
local M = {}

local Cache = {}

Cache.new = function(ttl_map)
  return {
    data = {},
    ts = {},
    widths = {},
    ttl = ttl_map or {},
  }
end

Cache.now_ms = function()
  return uv.hrtime() / 1e6
end

Cache.valid = function(cache, key)
  local v = cache.data[key]
  if v == nil then
    return false
  end
  local created = cache.ts[key]
  if not created then
    return false
  end
  local ttl = cache.ttl[key] or 1000
  return (Cache.now_ms() - created) < ttl
end

Cache.update = function(cache, key, value)
  cache.data[key] = value
  cache.ts[key] = Cache.now_ms()
  if type(value) == "string" then
    local plain = value:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", "")
    cache.widths[key] = fn.strdisplaywidth(plain)
  else
    cache.widths[key] = nil
  end
end

Cache.get_or_set = function(cache, key, fnc)
  if Cache.valid(cache, key) then
    return cache.data[key]
  end
  local ok, v = pcall(fnc)
  if not ok then
    v = ""
  end
  Cache.update(cache, key, v)
  return v
end

Cache.invalidate = function(cache, keys)
  if not keys then
    return
  end
  if type(keys) == "string" then
    keys = { keys }
  end
  for _, k in ipairs(keys) do
    cache.data[k] = nil
    cache.ts[k] = nil
    cache.widths[k] = nil
  end
end

local window_caches = {}
local window_git_data = {}
local window_file_icon_data = {}

local get_window_cache = function(winid)
  if not window_caches[winid] then
    local bt = api.nvim_get_option_value("buftype", { buf = api.nvim_win_get_buf(winid) })
    if bt == "popup" then
      window_caches[winid] = Cache.new({
        mode = 50,
        simple_title = 3000,
        inactive_filename = 3000,
      })
    else
      window_caches[winid] = Cache.new({
        mode = 50,
        file_info = 200,
        directory = 60000,
        git_branch = 60000,
        diagnostics = 500,
        lsp_status = 2000,
        encoding = 120000,
        simple_title = 3000,
        inactive_filename = 3000,
      })
    end
  end
  return window_caches[winid]
end

local cleanup_window_cache = function(winid)
  window_caches[winid] = nil
  window_git_data[winid] = nil
  window_file_icon_data[winid] = nil
end

local config = {
  seps = { left = "", right = "", section = " | " },
  exclude = {
    buftypes = {
      terminal = true,
      prompt = true
    },
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

local hl = function(name, text)
  return string.format("%%#%s#%s%%*", name, text)
end

local loaded = {}
local safe_require = function(mod)
  if loaded[mod] ~= nil then
    return loaded[mod]
  end
  local ok, res = pcall(require, mod)
  loaded[mod] = ok and res or false
  return loaded[mod]
end

local get_file_icon = function(winid, filename, extension, use_colors)
  if not window_file_icon_data[winid] then
    window_file_icon_data[winid] = {}
  end

  local cache = window_file_icon_data[winid]
  local cache_key = filename .. "." .. (extension or "") .. (use_colors and "_colored" or "_plain")

  local cached_value = cache[cache_key]

  if type(cached_value) == "string" then
    return cached_value
  end

  if cached_value == false then
    return ""
  end

  cache[cache_key] = false

  vim.schedule(function()
    if not api.nvim_win_is_valid(winid) then
      return
    end

    local devicons = safe_require("nvim-web-devicons")
    local icon_result = ""

    if devicons then
      if not devicons.has_loaded() then
        devicons.setup {}
      end

      local icon, hl_group = devicons.get_icon(filename, extension)
      if icon and icon ~= "" then
        if use_colors and hl_group and hl_group ~= "" then
          icon_result = hl(hl_group, icon) .. " "
        else
          icon_result = icon .. " "
        end
      end
    end

    cache[cache_key] = icon_result

    local sl_cache = get_window_cache(winid)
    Cache.invalidate(sl_cache, { "file_info", "inactive_filename" })
    M.refresh_window(winid)
  end)

  return ""
end

local fetch_git_branch = function(winid, root)
  local function on_exit(job_output)
    if not window_git_data[winid] then return end

    local branch_hl = ""
    if job_output and job_output.code == 0 and job_output.stdout then
      local branch = job_output.stdout:gsub("%s*$", "")
      if branch ~= "" then
        branch_hl = hl("StatusLineGit", icons.git .. " " .. branch)
      end
    end

    window_git_data[winid][root] = branch_hl

    if api.nvim_win_is_valid(winid) then
      local cache = get_window_cache(winid)
      Cache.invalidate(cache, "git_branch")
      M.refresh_window(winid)
    end
  end

  vim.system(
    { "git", "symbolic-ref", "--short", "HEAD" },
    { cwd = root, text = true, timeout = 2000 },
    vim.schedule_wrap(on_exit)
  )
end

local create_components = function(winid, bufnr)
  local cache = get_window_cache(winid)
  local component = {}

  component.mode = function()
    return Cache.get_or_set(cache, "mode", function()
      local m = modes[(api.nvim_get_mode() or {}).mode] or { " ? ", "StatusLineNormal" }
      return hl(m[2], m[1])
    end)
  end

  component.file_info = function()
    return Cache.get_or_set(cache, "file_info", function()
      local name = api.nvim_buf_get_name(bufnr)
      local filename = name == "" and "[No Name]" or fn.fnamemodify(name, ":t")
      local extension = fn.fnamemodify(filename, ":e")
      local icon = get_file_icon(winid, filename, extension, true)

      local readonly_flag = api.nvim_get_option_value("readonly", { buf = bufnr })
        and hl("StatusLineReadonly", icons.readonly .. " ") or ""

      local file_part = hl("StatusLineFile", icon .. filename)

      local modified_flag = api.nvim_get_option_value("modified", { buf = bufnr })
        and hl("StatusLineModified", " " .. icons.modified) or ""

      return readonly_flag .. file_part .. modified_flag
    end)
  end

  component.inactive_filename = function()
    return Cache.get_or_set(cache, "inactive_filename", function()
      local name = api.nvim_buf_get_name(bufnr)
      local filename = name == "" and "[No Name]" or fn.fnamemodify(name, ":t")
      local extension = fn.fnamemodify(filename, ":e")
      local icon = get_file_icon(winid, filename, extension)
      local modified_flag = api.nvim_get_option_value("modified", { buf = bufnr })
        and " " .. icons.modified or ""

      return icon .. filename .. modified_flag
    end)
  end

  component.simple_title = function()
    return Cache.get_or_set(cache, "simple_title", function()
      local bt = api.nvim_get_option_value("buftype", { buf = bufnr })
      local ft = api.nvim_get_option_value("filetype", { buf = bufnr })
      local title_map = {
        buftype = {
          terminal = icons.terminal .. " terminal",
          popup = icons.dock .. " Popup",
        },
        filetype = {
          lazy = icons.sleep .. " Lazy",
          ["neo-tree"] = icons.file_tree .. " File Explorer",
          ["neo-tree-popup"] = icons.file_tree .. " File Explorer",
          NvimTree = icons.file_tree .. " Files Explorer",
          lspinfo = icons.info .. " LSP Info",
          checkhealth = icons.status .. " Health",
          man = icons.book .. " Manual",
          qf = icons.fix .. " Quickfix",
          help = icons.help .. " Help",
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

  component.git_branch = function()
    return Cache.get_or_set(cache, "git_branch", function()
      local buf_name = api.nvim_buf_get_name(bufnr)
      local buf_dir = buf_name ~= "" and fn.fnamemodify(buf_name, ":h") or fn.getcwd()
      local gitdir = vim.fs.find({ ".git" }, { upward = true, path = buf_dir })

      if not gitdir or not gitdir[1] then return "" end
      local root = vim.fs.dirname(gitdir[1])

      if not window_git_data[winid] then
        window_git_data[winid] = {}
      end

      local git_cache = window_git_data[winid]
      local cached_value = git_cache[root]

      if type(cached_value) == "string" then return cached_value end
      if cached_value == false then return "" end

      git_cache[root] = false
      vim.schedule(function() fetch_git_branch(winid, root) end)
      return ""
    end)
  end

  component.directory = function()
    return Cache.get_or_set(cache, "directory", function()
      local name = api.nvim_buf_get_name(bufnr)
      local dir_path

      if name == "" then
        dir_path = fn.getcwd()
      else
        dir_path = vim.fs.dirname(name)
        if dir_path == "." then
          dir_path = fn.getcwd()
        end
      end

      local display_name = vim.fn.fnamemodify(dir_path, ":~")

      if display_name and display_name ~= "" and display_name ~= "." then
        return hl("StatusLineDirectory", icons.folder .. " " .. display_name)
      end
      return ""
    end)
  end

  component.diagnostics = function()
    return Cache.get_or_set(cache, "diagnostics", function()
      local counts = vim.diagnostic.count(bufnr)
      local s = vim.diagnostic.severity
      local sev_map = {
        { s.ERROR, "StatusLineDiagError", icons.error },
        { s.WARN, "StatusLineDiagWarn", icons.warn },
        { s.INFO, "StatusLineDiagInfo", icons.info },
        { s.HINT, "StatusLineDiagHint", icons.hint },
      }
      local p = {}
      for _, v in ipairs(sev_map) do
        local c = counts[v[1]]
        if c and c > 0 then p[#p + 1] = hl(v[2], v[3] .. " " .. c) end
      end
      return table.concat(p, " ")
    end)
  end

  component.lsp_status = function()
    return Cache.get_or_set(cache, "lsp_status", function()
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      if not clients or #clients == 0 then return "" end
      local names = {}
      for _, c in ipairs(clients) do names[#names + 1] = c.name end
      return hl("StatusLineLsp", icons.lsp .. " " .. table.concat(names, ", "))
    end)
  end

  return component
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

local is_active_window = function(winid)
  return winid == api.nvim_get_current_win()
end

M.refresh_window = function(winid)
  if not api.nvim_win_is_valid(winid) then
    cleanup_window_cache(winid)
    return
  end

  local is_active = is_active_window(winid)
  local is_excluded = is_excluded_buftype(winid)

  local expr
  if is_excluded then
    expr = string.format('%%!v:lua.require("ui.statusline").status_simple(%d)', winid)
  elseif is_active then
    expr = string.format('%%!v:lua.require("ui.statusline").status_advanced(%d)', winid)
  else
    expr = string.format('%%!v:lua.require("ui.statusline").status_inactive(%d)', winid)
  end

  vim.wo[winid].statusline = expr
end

M.refresh = function(win)
  if win then
    M.refresh_window(win)
  else
    for _, w in ipairs(api.nvim_list_wins()) do
      M.refresh_window(w)
    end
  end
end

M.status_simple = function(winid)
  if not api.nvim_win_is_valid(winid) then return "" end
  local bufnr = api.nvim_win_get_buf(winid)
  local C = create_components(winid, bufnr)
  local center = C.simple_title()
  return "%=" .. center .. "%="
end

M.status_inactive = function(winid)
  if not api.nvim_win_is_valid(winid) then return "" end
  local bufnr = api.nvim_win_get_buf(winid)
  local C = create_components(winid, bufnr)
  local center = C.inactive_filename()
  return "%=" .. center .. "%="
end

M.status_advanced = function(winid)
  if not api.nvim_win_is_valid(winid) then return "" end

  local bufnr = api.nvim_win_get_buf(winid)
  local cache = get_window_cache(winid)
  local C = create_components(winid, bufnr)

  local left_segments = { C.mode() }

  local directory = C.directory()
  if directory ~= "" then left_segments[#left_segments + 1] = directory end

  local git_branch = C.git_branch()
  if git_branch ~= "" then left_segments[#left_segments + 1] = git_branch end

  local left = table.concat(left_segments, " ")

  local right_list = {}
  local function push(v) if v and v ~= "" then right_list[#right_list + 1] = v end end

  push(C.diagnostics())
  push(C.lsp_status())

  push(hl("StatusLineLabel", "Ln ") .. hl("StatusLineValue", "%l") ..
    hl("StatusLineLabel", ", Col ") .. hl("StatusLineValue", "%v"))
  push(hl("StatusLineValue", "%P"))

  local right = table.concat(right_list, hl("StatusLineSeparator", config.seps.section))
  local center = C.file_info()
  local w_left = width_for(cache, left)
  local w_right = width_for(cache, right)
  local w_center = cache.widths.file_info or width_for(cache, center)
  local w_win = api.nvim_win_get_width(winid)

  if (w_win - (w_left + w_right)) >= w_center + 4 then
    local gap = math.max(1, math.floor((w_win - w_center) / 2) - w_left)
    return left .. string.rep(" ", gap) .. center .. "%=" .. right
  end
  return left .. " " .. center .. "%=" .. right
end

-- M.simple_statusline = function()
--   local winid = api.nvim_get_current_win()
--   return M.status_simple(winid)
-- end
--
-- M.statusline = function()
--   local winid = api.nvim_get_current_win()
--   return M.status_advanced(winid)
-- end
--
local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

api.nvim_create_autocmd("ModeChanged", {
  group = group,
  callback = function()
    local winid = api.nvim_get_current_win()
    local cache = get_window_cache(winid)
    Cache.invalidate(cache, "mode")
    M.refresh_window(winid)
  end
})

api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
  group = group,
  callback = function()
    window_git_data = {}
    for winid, cache in pairs(window_caches) do
      Cache.invalidate(cache, "git_branch")
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
    Cache.invalidate(cache,
      { "git_branch", "file_info", "directory", "lsp_status", "diagnostics", "simple_title", "inactive_filename" })
    M.refresh_window(winid)
  end
})

api.nvim_create_autocmd("DiagnosticChanged", {
  group = group,
  callback = function(ev)
    local buf = ev.buf
    for _, winid in ipairs(api.nvim_list_wins()) do
      if api.nvim_win_get_buf(winid) == buf then
        local cache = get_window_cache(winid)
        Cache.invalidate(cache, "diagnostics")
        M.refresh_window(winid)
      end
    end
  end
})

api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
  group = group,
  callback = function(ev)
    local buf = ev.buf
    for _, winid in ipairs(api.nvim_list_wins()) do
      if api.nvim_win_get_buf(winid) == buf then
        local cache = get_window_cache(winid)
        Cache.invalidate(cache, "lsp_status")
        M.refresh_window(winid)
      end
    end
  end
})

api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
  group = group,
  callback = function() vim.cmd("redrawstatus") end
})

api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
  group = group,
  callback = function() M.refresh() end
})

api.nvim_create_autocmd("WinClosed", {
  group = group,
  callback = function(ev)
    local winid = tonumber(ev.match)
    if winid then cleanup_window_cache(winid) end
  end
})

return M
