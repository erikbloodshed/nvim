local api, fn = vim.api, vim.fn
local autocmd = vim.api.nvim_create_autocmd
local severity = vim.diagnostic.severity
local icons = require("ui.icons")

local M = {}

local nvim_win_is_valid = api.nvim_win_is_valid
local nvim_win_get_buf = api.nvim_win_get_buf
local nvim_buf_get_name = api.nvim_buf_get_name
local nvim_get_current_win = api.nvim_get_current_win
local nvim_list_wins = api.nvim_list_wins
local nvim_win_get_width = api.nvim_win_get_width
local nvim_get_mode = api.nvim_get_mode

local sev_map = {
  { severity.ERROR, "DiagnosticError", icons.error },
  { severity.WARN, "DiagnosticWarn", icons.warn },
  { severity.INFO, "DiagnosticInfo", icons.info },
  { severity.HINT, "DiagnosticHint", icons.hint },
}

-- Pre-compile format strings
local HL_FORMAT = "%%#%s#%s%%*"
local STATUS_EXPR_SIMPLE = '%%!v:lua.require("ui.statusline").status_simple(%d)'
local STATUS_EXPR_ADVANCED = '%%!v:lua.require("ui.statusline").status_advanced(%d)'
local STATUS_EXPR_INACTIVE = '%%!v:lua.require("ui.statusline").status_inactive(%d)'

local cache_new = function()
  return {
    data = {},
    widths = {},
  }
end

local cache_update = function(cache, key, value)
  cache.data[key] = value
  -- Optimize string width calculation
  if type(value) == "string" then
    -- Pre-compile regex patterns for better performance
    local plain = value:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", "")
    cache.widths[key] = fn.strdisplaywidth(plain)
  else
    cache.widths[key] = nil
  end
end

local cache_lookup = function(cache, key, fnc)
  local value = cache.data[key]
  if value ~= nil then return value end
  local ok, res = pcall(fnc)
  cache_update(cache, key, ok and res or "")
  return res
end

local cache_invalidate = function(cache, keys)
  if not keys then return end
  if type(keys) == "string" then
    cache.data[keys] = nil
    cache.widths[keys] = nil
  else
    for i = 1, #keys do
      local k = keys[i]
      cache.data[k] = nil
      cache.widths[k] = nil
    end
  end
end

-- Use weak tables for automatic garbage collection
local win_caches = setmetatable({}, { __mode = "k" })
local win_git_data = setmetatable({}, { __mode = "k" })
local win_file_icon_data = setmetatable({}, { __mode = "k" })

local get_win_cache = function(winid)
  local cache = win_caches[winid]
  if not cache then
    cache = cache_new()
    win_caches[winid] = cache
  end
  return cache
end

local cleanup_win_cache = function(winid)
  win_caches[winid] = nil
  win_git_data[winid] = nil
  win_file_icon_data[winid] = nil
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
  return string.format(HL_FORMAT, name, text)
end

local loaded = {}

local safe_require = function(mod)
  local cached = loaded[mod]
  if cached ~= nil then return cached end
  local ok, res = pcall(require, mod)
  loaded[mod] = ok and res or false
  return loaded[mod]
end

-- Cache buffer properties to avoid repeated vim.bo lookups
local buf_cache = setmetatable({}, { __mode = "k" })

local get_buf_props = function(buf)
  local props = buf_cache[buf]
  if not props then
    props = {
      buftype = vim.bo[buf].buftype,
      filetype = vim.bo[buf].filetype,
      readonly = vim.bo[buf].readonly,
      modified = vim.bo[buf].modified,
    }
    buf_cache[buf] = props
  end
  return props
end

local is_excluded_buftype = function(win)
  if not nvim_win_is_valid(win) then return false end
  local buf = nvim_win_get_buf(win)
  local props = get_buf_props(buf)
  return config.exclude.buftypes[props.buftype] or config.exclude.filetypes[props.filetype]
end

local is_active_win = function(winid)
  return winid == nvim_get_current_win()
end

local refresh_win = function(winid)
  if not nvim_win_is_valid(winid) then
    cleanup_win_cache(winid)
    return
  end

  local is_excluded = is_excluded_buftype(winid)
  local is_active = is_active_win(winid)

  local expr
  if is_excluded then
    expr = string.format(STATUS_EXPR_SIMPLE, winid)
  elseif is_active then
    expr = string.format(STATUS_EXPR_ADVANCED, winid)
  else
    expr = string.format(STATUS_EXPR_INACTIVE, winid)
  end

  vim.wo[winid].statusline = expr
end

local get_file_icon = function(winid, filename, extension, use_colors)
  local file_icon_cache = win_file_icon_data[winid]
  if not file_icon_cache then
    file_icon_cache = {}
    win_file_icon_data[winid] = file_icon_cache
  end

  local cache_key = filename .. "." .. (extension or "") .. (use_colors and "_c" or "_p")
  local cached_value = file_icon_cache[cache_key]

  if type(cached_value) == "string" then return cached_value end
  if cached_value == false then return "" end

  file_icon_cache[cache_key] = false

  vim.schedule(function()
    if not nvim_win_is_valid(winid) then
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

    file_icon_cache[cache_key] = icon_result

    local sl_cache = get_win_cache(winid)
    cache_invalidate(sl_cache, { "file_info", "inactive_filename" })
    refresh_win(winid)
  end)

  return ""
end

local fetch_git_branch = function(winid, root)
  local function on_exit(job_output)
    local git_data = win_git_data[winid]
    if not git_data then return end

    local branch_hl = ""
    if job_output and job_output.code == 0 and job_output.stdout then
      local branch = job_output.stdout:gsub("%s*$", "")
      if branch ~= "" then
        branch_hl = hl("StatusLineGit", icons.git .. " " .. branch)
      end
    end

    git_data[root] = branch_hl

    if nvim_win_is_valid(winid) then
      local cache = get_win_cache(winid)
      cache_invalidate(cache, "git_branch")
      refresh_win(winid)
    end
  end

  vim.system(
    { "git", "symbolic-ref", "--short", "HEAD" },
    { cwd = root, text = true, timeout = 2000 },
    vim.schedule_wrap(on_exit)
  )
end

local get_file_parts = function(winid, bufnr, is_active)
  local name = nvim_buf_get_name(bufnr)
  local filename = name == "" and "[No Name]" or fn.fnamemodify(name, ":t")
  local extension = fn.fnamemodify(filename, ":e")
  local icon = get_file_icon(winid, filename, extension, is_active)
  return filename, icon
end

-- Pre-create commonly used strings
local STATUS_FLAGS = {
  readonly = " " .. icons.readonly,
  modified = " " .. icons.modified,
}

local create_components = function(winid, bufnr)
  local cache = get_win_cache(winid)
  local component = {}

  component.mode = function()
    return cache_lookup(cache, "mode", function()
      local mode = (nvim_get_mode() or {}).mode
      local m = modes[mode] or { " ? ", "StatusLineNormal" }
      return hl(m[2], m[1])
    end)
  end

  component.file_info = function()
    return cache_lookup(cache, "file_info", function()
      local filename, icon = get_file_parts(winid, bufnr, true)
      local props = get_buf_props(bufnr)

      local status_flag = ""
      if props.readonly then
        status_flag = hl("StatusLineReadonly", STATUS_FLAGS.readonly)
      elseif props.modified then
        status_flag = hl("StatusLineModified", STATUS_FLAGS.modified)
      end

      local file_part = hl("StatusLineFile", icon .. filename)
      return file_part .. status_flag
    end)
  end

  component.inactive_filename = function()
    return cache_lookup(cache, "inactive_filename", function()
      local filename, icon = get_file_parts(winid, bufnr, false)
      local props = get_buf_props(bufnr)

      local status_flag = ""
      if props.readonly then
        status_flag = STATUS_FLAGS.readonly
      elseif props.modified then
        status_flag = STATUS_FLAGS.modified
      end

      return icon .. filename .. status_flag
    end)
  end

  component.simple_title = function()
    return cache_lookup(cache, "simple_title", function()
      local props = get_buf_props(bufnr)

      -- Static lookup table
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

      local title = title_map.buftype[props.buftype] or
        title_map.filetype[props.filetype] or
        "no file"

      return hl("String", title)
    end)
  end

  component.git_branch = function()
    return cache_lookup(cache, "git_branch", function()
      local buf_name = nvim_buf_get_name(bufnr)
      local buf_dir = buf_name ~= "" and fn.fnamemodify(buf_name, ":h") or fn.getcwd()
      local gitdir = vim.fs.find({ ".git" }, { upward = true, path = buf_dir })

      if not gitdir or not gitdir[1] then return "" end
      local root = vim.fs.dirname(gitdir[1])

      local git_data = win_git_data[winid]
      if not git_data then
        git_data = {}
        win_git_data[winid] = git_data
      end

      local cached_value = git_data[root]

      if type(cached_value) == "string" then return cached_value end
      if cached_value == false then return "" end

      git_data[root] = false
      vim.schedule(function() fetch_git_branch(winid, root) end)
      return ""
    end)
  end

  component.directory = function()
    return cache_lookup(cache, "directory", function()
      local name = nvim_buf_get_name(bufnr)
      local dir_path

      if name == "" then
        dir_path = fn.getcwd()
      else
        dir_path = vim.fs.dirname(name)
        if dir_path == "." then
          dir_path = fn.getcwd()
        end
      end

      local display_name = fn.fnamemodify(dir_path, ":~")

      if display_name and display_name ~= "" and display_name ~= "." then
        return hl("Directory", icons.folder .. " " .. display_name)
      end
      return ""
    end)
  end

  component.diagnostics = function()
    return cache_lookup(cache, "diagnostics", function()
      local counts = vim.diagnostic.count(bufnr)

      if not counts or vim.tbl_isempty(counts) then
        return hl("DiagnosticOk", icons.ok)
      end

      -- Pre-allocate table with max size
      local p = {}
      local idx = 0
      for i = 1, #sev_map do
        local val = sev_map[i]
        local count = counts[val[1]]
        if count and count > 0 then
          idx = idx + 1
          p[idx] = hl(val[2], val[3] .. " " .. count)
        end
      end
      return table.concat(p, " ", 1, idx)
    end)
  end

  component.lsp_status = function()
    return cache_lookup(cache, "lsp_status", function()
      local clients = vim.lsp.get_clients({ bufnr = bufnr })
      if not clients or #clients == 0 then return "" end

      -- Pre-allocate table
      local names = {}
      for i = 1, #clients do
        names[i] = clients[i].name
      end
      return hl("StatusLineLsp", icons.lsp .. " " .. table.concat(names, ", "))
    end)
  end

  return component
end

local width_for = function(cache, key_or_str)
  local width = cache.widths[key_or_str]
  if width then return width end

  if type(key_or_str) == "string" then
    local plain = key_or_str:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", "")
    return fn.strdisplaywidth(plain)
  end
  return 0
end

M.status_simple = function(winid)
  if not nvim_win_is_valid(winid) then return "" end
  local bufnr = nvim_win_get_buf(winid)
  local components = create_components(winid, bufnr)
  return "%=" .. components.simple_title() .. "%="
end

M.status_inactive = function(winid)
  if not nvim_win_is_valid(winid) then return "" end
  local bufnr = nvim_win_get_buf(winid)
  local components = create_components(winid, bufnr)
  local center = components.inactive_filename()
  return "%=" .. center .. "%="
end

-- Pre-create static strings
local POSITION_FORMAT = table.concat({
  hl("StatusLineLabel", "Ln "),
  hl("StatusLineValue", "%l"),
  hl("StatusLineLabel", ", Col "),
  hl("StatusLineValue", "%v")
}, "")

M.status_advanced = function(winid)
  if not nvim_win_is_valid(winid) then return "" end
  local bufnr = nvim_win_get_buf(winid)
  local cache = get_win_cache(winid)
  local components = create_components(winid, bufnr)

  -- Build left segments
  local left_segments = { components.mode() }
  local left_idx = 1

  local directory = components.directory()
  if directory ~= "" then
    left_idx = left_idx + 1
    left_segments[left_idx] = directory
  end

  local git_branch = components.git_branch()
  if git_branch ~= "" then
    left_idx = left_idx + 1
    left_segments[left_idx] = git_branch
  end

  local left = table.concat(left_segments, " ", 1, left_idx)

  -- Build right segments efficiently
  local right_list = {}
  local right_idx = 0

  local diag = components.diagnostics()
  if diag and diag ~= "" then
    right_idx = right_idx + 1
    right_list[right_idx] = diag
  end

  local lsp = components.lsp_status()
  if lsp and lsp ~= "" then
    right_idx = right_idx + 1
    right_list[right_idx] = lsp
  end

  right_idx = right_idx + 1
  right_list[right_idx] = POSITION_FORMAT

  right_idx = right_idx + 1
  right_list[right_idx] = hl("StatusLineValue", "%P")

  local right = table.concat(right_list, hl("StatusLineSeparator", config.seps.section), 1, right_idx)
  local center = components.file_info()

  local w_left = width_for(cache, left)
  local w_right = width_for(cache, right)
  local w_center = cache.widths.file_info or width_for(cache, center)
  local w_win = nvim_win_get_width(winid)

  if (w_win - (w_left + w_right)) >= w_center + 4 then
    local gap = math.max(1, math.floor((w_win - w_center) / 2) - w_left)
    return left .. string.rep(" ", gap) .. center .. "%=" .. right
  end

  return table.concat({ left, center, right }, "%=")
end

local refresh = function(win)
  if win then
    refresh_win(win)
  else
    for _, w in ipairs(nvim_list_wins()) do
      refresh_win(w)
    end
  end
end

local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

-- Invalidate buffer cache when buffer properties change
local invalidate_buf_cache = function(buf)
  buf_cache[buf] = nil
end

autocmd("ModeChanged", {
  group = group,
  callback = function()
    local winid = nvim_get_current_win()
    local cache = get_win_cache(winid)
    cache_invalidate(cache, "mode")
    refresh_win(winid)
  end
})

autocmd({ "FocusGained", "DirChanged" }, {
  group = group,
  callback = function()
    win_git_data = {}
    for winid, cache in pairs(win_caches) do
      cache_invalidate(cache, "git_branch")
      if nvim_win_is_valid(winid) then
        refresh_win(winid)
      end
    end
  end,
})

autocmd("BufEnter", {
  group = group,
  callback = function()
    local winid = nvim_get_current_win()
    local cache = get_win_cache(winid)
    cache_invalidate(cache,
      { "git_branch", "file_info", "directory", "lsp_status", "diagnostics", "inactive_filename" })
    refresh_win(winid)
  end
})

autocmd("BufModifiedSet", {
  group = group,
  callback = function(ev)
    local buf = ev.buf
    invalidate_buf_cache(buf)
    for _, winid in ipairs(nvim_list_wins()) do
      if nvim_win_get_buf(winid) == buf then
        local cache = get_win_cache(winid)
        cache_invalidate(cache, { "file_info", "inactive_filename" })
        refresh_win(winid)
      end
    end
  end
})

autocmd({ "LspAttach", "LspDetach", "DiagnosticChanged" }, {
  group = group,
  callback = function(ev)
    local buf = ev.buf
    for _, winid in ipairs(nvim_list_wins()) do
      if nvim_win_get_buf(winid) == buf then
        local cache = get_win_cache(winid)
        cache_invalidate(cache, { "lsp_status", "diagnostics" })
        refresh_win(winid)
      end
    end
  end
})

autocmd({ "VimResized", "WinResized" }, {
  group = group,
  callback = function()
    api.nvim_cmd({ cmd = "redrawstatus" }, {})
  end
})

autocmd({ "BufWinEnter", "WinEnter" }, {
  group = group,
  callback = function() refresh() end
})

autocmd("WinClosed", {
  group = group,
  callback = function(ev)
    local winid = tonumber(ev.match)
    if winid then cleanup_win_cache(winid) end
  end
})

-- Add autocmd to invalidate buffer cache on property changes
autocmd({ "BufWritePost", "FileType", "BufReadPost" }, {
  group = group,
  callback = function(ev)
    invalidate_buf_cache(ev.buf)
  end
})

return M
