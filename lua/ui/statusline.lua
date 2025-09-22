local api, fn = vim.api, vim.fn
local icons = require("ui.icons")

local config = {
  seps = " • ",
  exclude = {
    buftypes = { terminal = true, prompt = true },
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

local nvim_win_is_valid = api.nvim_win_is_valid
local nvim_win_get_buf = api.nvim_win_get_buf
local nvim_buf_get_name = api.nvim_buf_get_name
local nvim_get_current_win = api.nvim_get_current_win
local nvim_list_wins = api.nvim_list_wins
local nvim_win_get_width = api.nvim_win_get_width
local nvim_get_mode = api.nvim_get_mode
local autocmd = api.nvim_create_autocmd
local strformat = string.format
local tbl_concat = table.concat
local tbl_insert = table.insert
local tbl_isempty = vim.tbl_isempty
local severity = vim.diagnostic.severity

local HL_FORMAT = "%%#%s#%s%%*"
local function hl(name, text) return strformat(HL_FORMAT, name, text) end

local POS_FORMAT = tbl_concat({
  hl("StatusLineLabel", "Ln "), hl("StatusLineValue", "%l"),
  hl("StatusLineLabel", ", Col "), hl("StatusLineValue", "%v"),
})
local SEP = hl("StatusLineSeparator", config.seps)
local STATUS_EXPR_SIMPLE = '%%!v:lua.require"ui.statusline".status_simple(%d)'
local STATUS_EXPR_ADVANCED = '%%!v:lua.require"ui.statusline".status_advanced(%d)'
local STATUS_EXPR_INACTIVE = '%%!v:lua.require"ui.statusline".status_inactive(%d)'

local HL_READONLY = " " .. hl("StatusLineReadonly", icons.readonly)
local HL_MODIFIED = " " .. hl("StatusLineModified", icons.modified)

local severity_tbl = {
  hl("DiagnosticError", icons.error),
  hl("DiagnosticWarn", icons.warn),
  hl("DiagnosticInfo", icons.info),
  hl("DiagnosticHint", icons.hint),
}

local win_data = setmetatable({}, { __mode = "k" }) -- per-window: { cache, git, icons }
local buf_data = setmetatable({}, { __mode = "k" }) -- per-buffer: { lsp_clients }

local function cache_lookup(cache, key, fnc)
  local value = cache[key]
  if value ~= nil then return value end
  local ok, res = pcall(fnc)
  cache[key] = ok and res or ""
  return cache[key]
end

local function cache_invalidate(cache, keys)
  if not keys then return end
  if type(keys) == "string" then
    cache[keys] = nil
  else
    for i = 1, #keys do cache[keys[i]] = nil end
  end
end

-- window data access
local function get_win_data(winid)
  local d = win_data[winid]
  if not d then
    d = { cache = {}, git = {}, icons = {} }
    win_data[winid] = d
  end
  return d
end

local function cleanup_win(winid) win_data[winid] = nil end

-- buffer data access
local function get_buf_data(bufnr)
  local d = buf_data[bufnr]
  if not d then
    d = { lsp_clients = {} }
    buf_data[bufnr] = d
  end
  return d
end

local function cleanup_buf(bufnr) buf_data[bufnr] = nil end

-- mode map
local modes = {
  n = { display = " NOR ", hl = "StatusLineNormal" },
  i = { display = " INS ", hl = "StatusLineInsert" },
  v = { display = " VIS ", hl = "StatusLineVisual" },
  V = { display = " V-L ", hl = "StatusLineVisual" },
  ["\22"] = { display = " V-B ", hl = "StatusLineVisual" },
  s = { display = " SEL ", hl = "StatusLineSelect" },
  S = { display = " S-L ", hl = "StatusLineSelect" },
  ["\19"] = { display = " S-B ", hl = "StatusLineSelect" },
  r = { display = " REP ", hl = "StatusLineReplace" },
  R = { display = " REP ", hl = "StatusLineReplace" },
  Rv = { display = " R-V ", hl = "StatusLineReplace" },
  c = { display = " CMD ", hl = "StatusLineCommand" },
}

setmetatable(modes, {
  __index = function()
    return { display = " ??? ", hl = "StatusLineNormal" }
  end
})

-- buffer props (no caching)
local function get_buf_props(buf)
  return {
    buftype = vim.bo[buf].buftype,
    filetype = vim.bo[buf].filetype,
    readonly = vim.bo[buf].readonly,
    modified = vim.bo[buf].modified,
  }
end

local function is_excluded_buftype(win)
  if not nvim_win_is_valid(win) then return false end
  local props = get_buf_props(nvim_win_get_buf(win))
  local exclude = config.exclude
  return exclude.buftypes[props.buftype] or exclude.filetypes[props.filetype]
end

local function is_active_win(winid) return winid == nvim_get_current_win() end

local function refresh_win(winid)
  if not nvim_win_is_valid(winid) then
    cleanup_win(winid)
    return
  end
  local expr
  if is_excluded_buftype(winid) then
    expr = strformat(STATUS_EXPR_SIMPLE, winid)
  elseif is_active_win(winid) then
    expr = strformat(STATUS_EXPR_ADVANCED, winid)
  else
    expr = strformat(STATUS_EXPR_INACTIVE, winid)
  end
  vim.wo[winid].statusline = expr
end

-- icons
local function get_file_icon(winid, filename, extension, use_colors)
  local icons_cache = get_win_data(winid).icons
  local cache_key = filename .. "." .. (extension or "") .. (use_colors and "_c" or "_p")
  local cached_value = icons_cache[cache_key]
  if type(cached_value) == "string" then return cached_value end
  if cached_value == false then return "" end
  icons_cache[cache_key] = false

  vim.schedule(function()
    if not nvim_win_is_valid(winid) then return end
    local devicons = require("nvim-web-devicons")
    local icon_result = ""
    if devicons then
      local icon, hl_group = devicons.get_icon(filename, extension)
      if icon and icon ~= "" then
        if use_colors and hl_group and hl_group ~= "" then
          icon_result = hl(hl_group, icon) .. " "
        else
          icon_result = icon .. " "
        end
      end
    end
    icons_cache[cache_key] = icon_result
    cache_invalidate(get_win_data(winid).cache, { "file_info", "inactive_filename" })
    refresh_win(winid)
  end)
  return ""
end

local function fetch_git_branch(winid, root)
  local function on_exit(job_output)
    local git_data = get_win_data(winid).git
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
      cache_invalidate(get_win_data(winid).cache, "git_branch")
      refresh_win(winid)
    end
  end
  vim.system(
    { "git", "symbolic-ref", "--short", "HEAD" },
    { cwd = root, text = true, timeout = 2000 },
    vim.schedule_wrap(on_exit)
  )
end

local function mode_details()
  local mode = (nvim_get_mode() or {}).mode
  return modes[mode]
end

local function file_parts(bufnr)
  local name = nvim_buf_get_name(bufnr)
  if name == "" then return { filename = "[No Name]", extension = "" } end
  local filename = fn.fnamemodify(name, ":t")
  local extension = fn.fnamemodify(filename, ":e")
  return { filename = filename, extension = extension }
end

local function create_components(winid, bufnr)
  local wdata = get_win_data(winid)
  local cache = wdata.cache
  local component = {}

  -- Precompute mode details once for both mode and percentage components
  local mode_info = mode_details()

  component.mode = function()
    return hl(mode_info.hl, mode_info.display)
  end

  component.file_info = function()
    return cache_lookup(cache, "file_info", function()
      local parts = file_parts(bufnr)
      local icon = get_file_icon(winid, parts.filename, parts.extension, true)
      local props = get_buf_props(bufnr)
      local status = props.readonly and HL_READONLY or
        props.modified and HL_MODIFIED or ""
      return hl("StatusLineFile", icon .. parts.filename) .. status
    end)
  end

  component.inactive_filename = function()
    return cache_lookup(cache, "inactive_filename", function()
      local parts = file_parts(bufnr)
      local icon = get_file_icon(winid, parts.filename, parts.extension, false)
      local props = get_buf_props(bufnr)
      local status_flag = props.readonly and " " .. icons.readonly or
        props.modified and " " .. icons.modified or ""
      return strformat("%s%s%s", icon, parts.filename, status_flag)
    end)
  end

  component.simple_title = function()
    local props = get_buf_props(bufnr)
    local title_map = {
      buftype = { terminal = icons.terminal .. " terminal", popup = icons.dock .. " Popup" },
      filetype = {
        lazy = icons.sleep .. " Lazy",
        ["neo-tree"] = icons.file_tree .. " File Explorer",
        ["neo-tree-popup"] = icons.file_tree .. " File Explorer",
        lspinfo = icons.info .. " LSP Info",
        checkhealth = icons.status .. " Health",
        man = icons.book .. " Manual",
        qf = icons.fix .. " Quickfix",
        help = icons.help .. " Help",
      },
    }
    local title = title_map.buftype[props.buftype] or
      title_map.filetype[props.filetype] or "no file"
    return hl("String", title)
  end

  component.git_branch = function()
    return cache_lookup(cache, "git_branch", function()
      local buf_name = nvim_buf_get_name(bufnr)
      local buf_dir = buf_name ~= "" and fn.fnamemodify(buf_name, ":h") or fn.getcwd()
      local gitdir = vim.fs.find({ ".git" }, { upward = true, path = buf_dir })
      if not gitdir or not gitdir[1] then return "" end
      local root = vim.fs.dirname(gitdir[1])
      local git_data = wdata.git
      local cached_value = git_data[root]
      if type(cached_value) == "string" then return cached_value end
      if cached_value == false then return "" end
      git_data[root] = false
      vim.schedule(function() fetch_git_branch(winid, root) end)
      return ""
    end)
  end

  component.directory = function()
    local name = nvim_buf_get_name(bufnr)
    local dir_path = (name == "") and fn.getcwd() or vim.fs.dirname(name)
    if dir_path == "." then dir_path = fn.getcwd() end
    local display_name = fn.fnamemodify(dir_path, ":~")
    if display_name and display_name ~= "" and display_name ~= "." then
      return hl("Directory", icons.folder .. " " .. display_name)
    end
    return ""
  end

  component.lsp_status = function()
    return cache_lookup(cache, "lsp_status", function()
      local clients = get_buf_data(bufnr).lsp_clients
      if not clients or vim.tbl_isempty(clients) then return "" end
      local parts = {}
      for _, name in pairs(clients) do
        tbl_insert(parts, name)
      end
      return hl("StatusLineLsp", icons.lsp .. " " .. tbl_concat(parts, ", "))
    end)
  end

  component.diagnostics = function()
    local counts = vim.diagnostic.count(bufnr)
    if tbl_isempty(counts) then return hl("DiagnosticOk", icons.ok) end
    local parts = {}
    for idx = severity.ERROR, severity.INFO do
      local count = counts[idx]
      if count and count > 0 then
        tbl_insert(parts, severity_tbl[idx] .. ":" .. count)
      end
    end
    return tbl_concat(parts, " ")
  end

  component.position = function()
    return POS_FORMAT
  end

  component.percentage = function()
    return hl(mode_info.hl, " %P ")
  end

  return component
end

local function width_for(str)
  return fn.strdisplaywidth(str:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", ""))
end

local M = {}

M.status_simple = function(winid)
  if not nvim_win_is_valid(winid) then return "" end
  local components = create_components(winid, nvim_win_get_buf(winid))
  return strformat("%%=%s%%=", components.simple_title())
end

M.status_inactive = function(winid)
  if not nvim_win_is_valid(winid) then return "" end
  local components = create_components(winid, nvim_win_get_buf(winid))
  return strformat("%%=%s%%=", components.inactive_filename())
end

local function assemble(parts, sep)
  local tbl = {}
  for _, part in ipairs(parts) do
    if part ~= "" then tbl_insert(tbl, part) end
  end
  return tbl_concat(tbl, sep)
end

M.status_advanced = function(winid)
  if not nvim_win_is_valid(winid) then return "" end
  local bufnr = nvim_win_get_buf(winid)
  local c = create_components(winid, bufnr)

  local left = assemble({ c.mode(), c.directory(), c.git_branch() }, SEP)
  local center = c.file_info()
  local right = assemble({ c.diagnostics(), c.lsp_status(), c.position(), c.percentage() }, SEP)

  local w_left, w_right, w_center, w_win =
    width_for(left), width_for(right), width_for(center), nvim_win_get_width(winid)

  if (w_win - (w_left + w_right)) >= w_center + 4 then
    local gap = math.max(1, math.floor((w_win - w_center) / 2) - w_left)
    return strformat("%s%s%s%%=%s", left, string.rep(" ", gap), center, right)
  end

  return assemble({ left, center, right }, "%=")
end

local function refresh(win)
  if win then
    refresh_win(win)
  else
    for _, w in ipairs(nvim_list_wins()) do refresh_win(w) end
  end
end

local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

local function update_win_for_buf(buf, cache_keys)
  for _, winid in ipairs(fn.win_findbuf(buf)) do
    cache_invalidate(get_win_data(winid).cache, cache_keys)
    refresh_win(winid)
  end
end

-- autocmds
autocmd("BufEnter", {
  group = group,
  callback = function()
    local winid = nvim_get_current_win()
    local bufnr = nvim_win_get_buf(winid)
    local name = nvim_buf_get_name(bufnr)
    local cache_keys = name == "" and { "directory", "git_branch", "file_info", "inactive_filename" }
      or { "file_info", "inactive_filename" }
    cache_invalidate(get_win_data(winid).cache, cache_keys)
    refresh_win(winid)
  end,
})

autocmd("FocusGained", {
  group = group,
  callback = function()
    local winid = nvim_get_current_win()
    cache_invalidate(get_win_data(winid).cache, "git_branch")
    refresh_win(winid)
  end,
})

autocmd("BufModifiedSet", {
  group = group,
  callback = function(ev)
    update_win_for_buf(ev.buf, { "file_info", "inactive_filename" })
  end,
})

autocmd({ "BufWritePost", "BufFilePost" }, {
  group = group,
  callback = function(ev)
    update_win_for_buf(ev.buf, { "file_info", "inactive_filename", "directory", "git_branch" })
  end,
})

autocmd("DirChanged", {
  group = group,
  callback = function()
    for _, winid in ipairs(nvim_list_wins()) do
      local bufnr = nvim_win_get_buf(winid)
      if nvim_buf_get_name(bufnr) == "" then
        cache_invalidate(get_win_data(winid).cache, { "directory", "git_branch" })
        refresh_win(winid)
      end
    end
  end,
})

autocmd("LspAttach", {
  group = group,
  callback = function(ev)
    local clients = get_buf_data(ev.buf).lsp_clients
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client then clients[client.id] = client.name end
    update_win_for_buf(ev.buf, "lsp_status")
  end,
})

autocmd("LspDetach", {
  group = group,
  callback = function(ev)
    local clients = get_buf_data(ev.buf).lsp_clients
    clients[ev.data.client_id] = nil
    update_win_for_buf(ev.buf, "lsp_status")
  end,
})

autocmd("DiagnosticChanged", {
  group = group,
  callback = function(ev)
    for _, winid in ipairs(fn.win_findbuf(ev.buf)) do
      refresh_win(winid)
    end
  end,
})

autocmd({ "VimResized", "WinResized" }, {
  group = group,
  callback = function() api.nvim_cmd({ cmd = "redrawstatus" }, {}) end,
})

autocmd({ "BufWinEnter", "WinEnter" }, {
  group = group,
  callback = function() refresh() end,
})

autocmd("WinClosed", {
  group = group,
  callback = function(ev)
    local winid = tonumber(ev.match)
    if winid then cleanup_win(winid) end
  end,
})

autocmd("BufWipeout", {
  group = group,
  callback = function(ev) cleanup_buf(ev.buf) end,
})

return M
