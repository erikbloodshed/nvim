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
      checkhealth = false,
      help = false,
      man = true,
      qf = true,
    },
  },
}

local highlight_map = {
  mode_normal = "StatusLineNormal",
  mode_insert = "StatusLineInsert",
  mode_visual = "StatusLineVisual",
  mode_select = "StatusLineSelect",
  mode_replace = "StatusLineReplace",
  mode_command = "StatusLineCommand",
  separator = "StatusLineSeparator",
  file = "StatusLineFile",
  readonly = "StatusLineReadonly",
  modified = "StatusLineModified",
  git = "StatusLineGit",
  lsp = "StatusLineLsp",
  directory = "Directory",
  position = "StatusLineValue",
  simple_title = "String",
  diagnostic_error = "DiagnosticError",
  diagnostic_warn = "DiagnosticWarn",
  diagnostic_info = "DiagnosticInfo",
  diagnostic_hint = "DiagnosticHint",
  diagnostic_ok = "DiagnosticOk",
}

local component_data = {
  modes = {
    n = { text = " NOR ", hl_key = "mode_normal" },
    i = { text = " INS ", hl_key = "mode_insert" },
    v = { text = " VIS ", hl_key = "mode_visual" },
    V = { text = " V-L ", hl_key = "mode_visual" },
    ["\22"] = { text = " V-B ", hl_key = "mode_visual" },
    s = { text = " SEL ", hl_key = "mode_select" },
    S = { text = " S-L ", hl_key = "mode_select" },
    ["\19"] = { text = " S-B ", hl_key = "mode_select" },
    r = { text = " REP ", hl_key = "mode_replace" },
    R = { text = " REP ", hl_key = "mode_replace" },
    Rv = { text = " R-V ", hl_key = "mode_replace" },
    c = { text = " CMD ", hl_key = "mode_command" },
  },
  simple_titles = {
    buftype = {
      terminal = { text = icons.terminal .. " terminal", hl_key = "simple_title" },
      popup = { text = icons.dock .. " Popup", hl_key = "simple_title" }
    },
    filetype = {
      lazy = { text = icons.sleep .. " Lazy", hl_key = "simple_title" },
      ["neo-tree"] = { text = icons.file_tree .. " File Explorer", hl_key = "simple_title" },
      ["neo-tree-popup"] = { text = icons.file_tree .. " File Explorer", hl_key = "simple_title" },
      lspinfo = { text = icons.info .. " LSP Info", hl_key = "simple_title" },
      checkhealth = { text = icons.status .. " Health", hl_key = "simple_title" },
      man = { text = icons.book .. " Manual", hl_key = "simple_title" },
      qf = { text = icons.fix .. " Quickfix", hl_key = "simple_title" },
      help = { text = icons.help .. " Help", hl_key = "simple_title" },
    },
  },
  diagnostics = {
    { icon = icons.error, hl_key = "diagnostic_error", severity_idx = 1 },
    { icon = icons.warn, hl_key = "diagnostic_warn", severity_idx = 2 },
    { icon = icons.info, hl_key = "diagnostic_info", severity_idx = 3 },
    { icon = icons.hint, hl_key = "diagnostic_hint", severity_idx = 4 },
  }
}

setmetatable(component_data.modes, {
  __index = function()
    return { text = " ??? ", hl_key = "mode_normal" }
  end
})

local nvim_win_is_valid = api.nvim_win_is_valid
local nvim_win_get_buf = api.nvim_win_get_buf
local nvim_buf_get_name = api.nvim_buf_get_name
local nvim_get_current_win = api.nvim_get_current_win
local nvim_list_wins = api.nvim_list_wins
local nvim_win_get_width = api.nvim_win_get_width
local nvim_get_mode = api.nvim_get_mode
local autocmd = api.nvim_create_autocmd
local tbl_concat = table.concat
local tbl_isempty = vim.tbl_isempty

local function apply_highlight(content, key_or_group)
  if not key_or_group then return content end
  local hl_group = highlight_map[key_or_group] or key_or_group
  if not hl_group or not content or content == "" then
    return content or ""
  end
  return string.format("%%#%s#%s%%*", hl_group, content)
end

local cache_keys = {
  all = {
    "file_info", "file_info_plain", "directory", "git_branch",
    "git_branch_plain", "diagnostics_hl", "diagnostics_plain",
  },
  git = { "git_branch", "git_branch_plain" },
  file = { "file_info", "file_info_plain" },
  dir = { "git_branch", "git_branch_plain", "directory" },
  diag = { "diagnostics_hl", "diagnostics_plain" }
}

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

local win_data = setmetatable({}, { __mode = "k" })

local function get_win_data(winid)
  local d = win_data[winid]
  if not d then
    d = { cache = {}, git = {}, icons = {} }
    win_data[winid] = d
  end
  return d
end

local function is_excluded_buftype(win)
  if not nvim_win_is_valid(win) then return false end
  local bufnr = nvim_win_get_buf(win)
  local bo = vim.bo[bufnr]
  local exclude = config.exclude
  return exclude.buftypes[bo.buftype] or exclude.filetypes[bo.filetype]
end

local status_expr = "%%!v:lua.require'ui.statusline'.status(%d)"

local function refresh_win(winid)
  if not nvim_win_is_valid(winid) then
    win_data[winid] = nil
    return
  end
  vim.wo[winid].statusline = string.format(status_expr, winid)
end

local get_file_parts = function(bufnr)
  local name = nvim_buf_get_name(bufnr)
  if name == "" then return { filename = "[No Name]", extension = "" } end
  local fname = fn.fnamemodify(name, ":t")
  local ext = fn.fnamemodify(fname, ":e")
  return { filename = fname, extension = ext }
end

local function get_file_icon(winid, file)
  local icons_cache = get_win_data(winid).icons
  local cache_key = file.filename .. "." .. (file.extension or "")
  local cached_value = icons_cache[cache_key]
  if cached_value ~= nil then
    return type(cached_value) == "table" and cached_value or { icon = "", hl = nil }
  end
  icons_cache[cache_key] = false
  vim.schedule(function()
    if not nvim_win_is_valid(winid) then return end
    local ok, icon_module = pcall(require, "nvim-web-devicons")
    local icon_result = { icon = "", hl = nil }
    if ok and icon_module then
      local icon, hl_group = icon_module.get_icon(file.filename, file.extension)
      if icon then
        icon_result = { icon = icon .. " ", hl = hl_group }
      end
    end
    icons_cache[cache_key] = icon_result
    cache_invalidate(get_win_data(winid).cache, cache_keys.file)
    refresh_win(winid)
  end)
  return { icon = "", hl = nil }
end

local function fetch_git_branch(winid, root)
  local function on_exit(job_output)
    local git_data = win_data[winid] and win_data[winid].git
    if not git_data then return end
    local branch_name = ""
    if job_output and job_output.code == 0 and job_output.stdout then
      branch_name = job_output.stdout:gsub("%s*$", "")
    end
    git_data[root] = branch_name
    if nvim_win_is_valid(winid) then
      cache_invalidate(get_win_data(winid).cache, cache_keys.git)
      refresh_win(winid)
    end
  end
  vim.system(
    { "git", "symbolic-ref", "--short", "HEAD" },
    { cwd = root, text = true, timeout = 2000 },
    vim.schedule_wrap(on_exit)
  )
end

local function maybe_hl(content, hl_key, apply_hl)
  if not apply_hl then return content end
  return apply_highlight(content, hl_key)
end

local function create_components(winid, bufnr, apply_hl)
  local mode_info = component_data.modes[(nvim_get_mode() or {}).mode]
  local wdata = get_win_data(winid)
  local cache = wdata.cache
  local component = {}

  component.mode = function()
    local content, hl_key = mode_info.text, mode_info.hl_key
    return maybe_hl(content, hl_key, apply_hl)
  end

  component.directory = function()
    local buf_name = nvim_buf_get_name(bufnr)
    local full_path = (buf_name == "") and fn.getcwd() or fn.fnamemodify(buf_name, ":p:h")
    local display_name = fn.fnamemodify(full_path, ":~")
    if display_name and display_name ~= "" then
      local content = icons.folder .. " " .. display_name
      return maybe_hl(content, "directory", apply_hl)
    end
    return ""
  end

  component.git_branch = function()
    local cache_key = apply_hl and "git_branch" or "git_branch_plain"
    return cache_lookup(cache, cache_key, function()
      local buf_name = nvim_buf_get_name(bufnr)
      local buf_dir = buf_name ~= "" and fn.fnamemodify(buf_name, ":h") or fn.getcwd()
      local gitdir = vim.fs.find({ ".git" }, { upward = true, path = buf_dir })
      if not gitdir or not gitdir[1] then return "" end
      local root = vim.fs.dirname(gitdir[1])
      local git_data = wdata.git
      local cached_branch_name = git_data[root]
      if type(cached_branch_name) == "string" then
        if cached_branch_name == "" then return "" end
        return maybe_hl(icons.git .. " " .. cached_branch_name, "git", apply_hl)
      else
        if cached_branch_name == nil then
          git_data[root] = false
          vim.schedule(function() fetch_git_branch(winid, root) end)
        end
        return ""
      end
    end)
  end

  component.file_info = function()
    local cache_key = apply_hl and "file_info" or "file_info_plain"
    return cache_lookup(cache, cache_key, function()
      local file = get_file_parts(bufnr)
      local icon_data = get_file_icon(winid, file)
      local icon_str = maybe_hl(icon_data.icon, icon_data.hl, apply_hl)
      local file_content = maybe_hl(file.filename, "file", apply_hl)
      local bo = vim.bo[bufnr]
      local status = bo.readonly and maybe_hl(" " .. icons.readonly, "readonly", apply_hl) or
        bo.modified and maybe_hl(" " .. icons.modified, "modified", apply_hl) or " "
      return icon_str .. file_content .. status
    end)
  end

  component.simple_title = function()
    local bo = vim.bo[bufnr]
    local title_data = component_data.simple_titles.buftype[bo.buftype] or
      component_data.simple_titles.filetype[bo.filetype]
    local content, hl_key = title_data and title_data.text or "no file",
      title_data and title_data.hl_key or "simple_title"
    return maybe_hl(content, hl_key, apply_hl)
  end

  component.diagnostics = function()
    local cache_key = apply_hl and "diagnostics_hl" or "diagnostics_plain"
    return cache_lookup(cache, cache_key, function()
      local counts = vim.diagnostic.count(bufnr)
      if tbl_isempty(counts) then return maybe_hl(icons.ok, "diagnostic_ok", apply_hl) end
      local parts = {}
      for _, diag_info in ipairs(component_data.diagnostics) do
        local count = counts[diag_info.severity_idx]
        if count and count > 0 then
          local content = diag_info.icon .. ":" .. count
          parts[#parts + 1] = maybe_hl(content, diag_info.hl_key, apply_hl)
        end
      end
      return tbl_concat(parts, " ")
    end)
  end

  component.lsp_status = function()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if not clients or vim.tbl_isempty(clients) then return "" end
    local names = {}
    for _, client in ipairs(clients) do
      names[#names + 1] = client.name
    end
    local content = icons.lsp .. " " .. table.concat(names, ", ")
    return maybe_hl(content, "lsp", apply_hl)
  end

  component.position = function()
    return maybe_hl("%l:%v", "position", apply_hl)
  end

  component.percentage = function()
    return maybe_hl(" %P ", mode_info.hl_key, apply_hl)
  end

  return component
end

local width_cache = setmetatable({}, { __mode = "k" })

local function width_for(str)
  if not str or str == "" then return 0 end
  local cached = width_cache[str]
  if cached then return cached end
  local cleaned = str:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", "")
  local width = fn.strdisplaywidth(cleaned)
  width_cache[str] = width
  return width
end

local function assemble(parts, sep)
  local tbl = {}
  for _, part in ipairs(parts) do
    if part ~= "" then tbl[#tbl + 1] = part end
  end
  return tbl_concat(tbl, sep)
end

local M = {}

M.status = function(winid)
  local bufnr = nvim_win_get_buf(winid)

  if is_excluded_buftype(winid) then
    local c = create_components(winid, bufnr, true)
    return "%=" .. c.simple_title() .. "%="
  end

  local highlight = winid == nvim_get_current_win()
  local c = create_components(winid, bufnr, highlight)
  local sep = highlight and apply_highlight(config.seps, "separator") or config.seps
  local left = assemble({ c.mode(), c.directory(), c.git_branch() }, sep)
  local center = c.file_info()
  local right = assemble({ c.diagnostics(), c.lsp_status(), c.position(), c.percentage() }, sep)
  local w_left, w_right, w_center, w_win =
    width_for(left), width_for(right), width_for(center), nvim_win_get_width(winid)

  if (w_win - (w_left + w_right)) >= w_center + 4 then
    local gap = math.max(1, math.floor((w_win - w_center) / 2) - w_left)
    return tbl_concat({ left, string.rep(" ", gap), center, "%=", right })
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

local update_win_for_buf = function(buf, keys)
  for _, winid in ipairs(fn.win_findbuf(buf)) do
    cache_invalidate(get_win_data(winid).cache, keys)
    refresh_win(winid)
  end
end

local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

autocmd({ "BufEnter", "BufWritePost"}, {
  group = group,
  callback = function(ev)
    update_win_for_buf(ev.buf, cache_keys.all)
  end,
})

autocmd("FocusGained", {
  group = group,
  callback = function(ev)
    update_win_for_buf(ev.buf, cache_keys.git)
  end,
})

autocmd("BufModifiedSet", {
  group = group,
  callback = function(ev)
    update_win_for_buf(ev.buf, cache_keys.file)
  end,
})

autocmd("DirChanged", {
  group = group,
  callback = function(ev)
    update_win_for_buf(ev.buf, cache_keys.dir)
  end,
})

autocmd("DiagnosticChanged", {
  group = group,
  callback = function(ev)
    update_win_for_buf(ev.buf, cache_keys.diag)
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
    if winid then win_data[winid] = nil end
  end,
})

return M
