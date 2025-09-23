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
local format = string.format
local tbl_concat = table.concat
local tbl_insert = table.insert
local tbl_isempty = vim.tbl_isempty

local function apply_highlight(content, key_or_group)
  local hl_group = highlight_map[key_or_group] or key_or_group
  if not hl_group or not content or content == "" then
    return content or ""
  end
  return format("%%#%s#%s%%*", hl_group, content)
end

local content_builders = {}

content_builders.get_mode_content = function()
  local mode = (nvim_get_mode() or {}).mode
  local mode_info = component_data.modes[mode]
  return mode_info.text, mode_info.hl_key
end

content_builders.get_file_parts = function(bufnr)
  local name = nvim_buf_get_name(bufnr)
  if name == "" then
    return { filename = "[No Name]", extension = "" }
  end
  local fname = fn.fnamemodify(name, ":t")
  local ext = fn.fnamemodify(fname, ":e")
  return { filename = fname, extension = ext }
end

content_builders.get_buf_props = function(buf)
  return {
    buftype = vim.bo[buf].buftype,
    filetype = vim.bo[buf].filetype,
    readonly = vim.bo[buf].readonly,
    modified = vim.bo[buf].modified,
  }
end

content_builders.get_file_status_content = function(props)
  if props.readonly then
    return " " .. icons.readonly, "readonly"
  elseif props.modified then
    return " " .. icons.modified, "modified"
  else
    return " ", nil
  end
end

content_builders.get_simple_title_content = function(props)
  local title_data = component_data.simple_titles.buftype[props.buftype] or
    component_data.simple_titles.filetype[props.filetype]

  if title_data then
    return title_data.text, title_data.hl_key
  end
  return "no file", "simple_title"
end

content_builders.get_directory_content = function(buf_name)
  local full_path = (buf_name == "") and fn.getcwd() or fn.fnamemodify(buf_name, ":p:h")
  local display_name = fn.fnamemodify(full_path, ":~")
  if display_name and display_name ~= "" then
    return icons.folder .. " " .. display_name, "directory"
  end
  return "", nil
end

content_builders.get_lsp_content = function(clients)
  if not clients or tbl_isempty(clients) then
    return "", nil
  end
  local parts = {}
  for _, name in pairs(clients) do
    tbl_insert(parts, name)
  end
  return icons.lsp .. " " .. tbl_concat(parts, ", "), "lsp"
end

content_builders.get_diagnostics_content = function(bufnr)
  local counts = vim.diagnostic.count(bufnr)
  if tbl_isempty(counts) then
    return icons.ok, "diagnostic_ok"
  end

  local parts = {}
  for _, diag_info in ipairs(component_data.diagnostics) do
    local count = counts[diag_info.severity_idx]
    if count and count > 0 then
      local content = diag_info.icon .. ":" .. count
      local highlighted = apply_highlight(content, diag_info.hl_key)
      tbl_insert(parts, highlighted)
    end
  end
  return tbl_concat(parts, " "), nil
end

local win_data = setmetatable({}, { __mode = "k" })
local buf_data = setmetatable({}, { __mode = "k" })

local cache_keys = {
  all = {
    "file_info", "file_info_plain", "inactive_filename", "directory",
    "git_branch", "git_branch_plain",
  },
  git = { "git_branch", "git_branch_plain" },
  file = { "file_info", "file_info_plain", "inactive_filename" },
  dir = { "git_branch", "git_branch_plain", "directory" }
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

local function get_win_data(winid)
  local d = win_data[winid]
  if not d then
    d = { cache = {}, git = {}, icons = {} }
    win_data[winid] = d
  end
  return d
end

local function cleanup_win(winid) win_data[winid] = nil end
local function cleanup_buf(bufnr) buf_data[bufnr] = nil end

local function is_excluded_buftype(win)
  if not nvim_win_is_valid(win) then return false end
  local props = content_builders.get_buf_props(nvim_win_get_buf(win))
  local exclude = config.exclude
  return exclude.buftypes[props.buftype] or exclude.filetypes[props.filetype]
end

local status_expr = "%%!v:lua.require'ui.statusline'.status(%d)"

local function refresh_win(winid)
  if not nvim_win_is_valid(winid) then cleanup_win(winid) return end
  vim.wo[winid].statusline = format(status_expr, winid)
end

local function get_file_icon(winid, filename, extension)
  local icons_cache = get_win_data(winid).icons
  local cache_key = filename .. "." .. (extension or "")
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
      local icon, hl_group = icon_module.get_icon(filename, extension)
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

local function create_components(winid, bufnr, apply_hl)
  local wdata = get_win_data(winid)
  local cache = wdata.cache
  local component = {}
  local highlight_fn = apply_hl and apply_highlight or function(content, _) return content end

  component.mode = function()
    local content, hl_key = content_builders.get_mode_content()
    return highlight_fn(content, hl_key)
  end

  component.file_info = function()
    local cache_key = apply_hl and "file_info" or "file_info_plain"
    return cache_lookup(cache, cache_key, function()
      local parts = content_builders.get_file_parts(bufnr)
      local icon_data = get_file_icon(winid, parts.filename, parts.extension)
      local icon_str
      if apply_hl and icon_data.hl then
        icon_str = apply_highlight(icon_data.icon, icon_data.hl)
      else
        icon_str = icon_data.icon
      end
      local props = content_builders.get_buf_props(bufnr)
      local status_content, status_hl_key = content_builders.get_file_status_content(props)
      local status = status_hl_key and highlight_fn(status_content, status_hl_key) or status_content
      local file_content = highlight_fn(parts.filename, "file")
      return icon_str .. file_content .. status
    end)
  end

  component.inactive_filename = function()
    return cache_lookup(cache, "inactive_filename", function()
      local parts = content_builders.get_file_parts(bufnr)
      local icon = get_file_icon(winid, parts.filename, parts.extension)
      local props = content_builders.get_buf_props(bufnr)
      local status_flag = props.readonly and " " .. icons.readonly or
        props.modified and " " .. icons.modified or ""
      return icon .. parts.filename .. status_flag
    end)
  end

  component.simple_title = function()
    local props = content_builders.get_buf_props(bufnr)
    local content, hl_key = content_builders.get_simple_title_content(props)
    return highlight_fn(content, hl_key)
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

        local content = icons.git .. " " .. cached_branch_name
        return apply_hl and highlight_fn(content, "git") or content
      else
        if cached_branch_name == nil then
          git_data[root] = false
          vim.schedule(function()
            fetch_git_branch(winid, root)
          end)
        end
        return ""
      end
    end)
  end

  component.directory = function()
    local buf_name = nvim_buf_get_name(bufnr)
    local content, hl_key = content_builders.get_directory_content(buf_name)
    return hl_key and highlight_fn(content, hl_key) or content
  end

  component.lsp_status = function()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if not clients or vim.tbl_isempty(clients) then
      return ""
    end

    local names = {}
    for _, client in ipairs(clients) do
      table.insert(names, client.name)
    end

    local content, hl_key = content_builders.get_lsp_content(names)
    return hl_key and highlight_fn(content, hl_key) or content
  end

  component.diagnostics = function()
    if apply_hl then
      local content, hl_key = content_builders.get_diagnostics_content(bufnr)
      return hl_key and highlight_fn(content, hl_key) or content
    else
      local counts = vim.diagnostic.count(bufnr)
      if tbl_isempty(counts) then
        return icons.ok
      end
      local parts = {}
      for _, diag_info in ipairs(component_data.diagnostics) do
        local count = counts[diag_info.severity_idx]
        if count and count > 0 then
          tbl_insert(parts, diag_info.icon .. ":" .. count)
        end
      end
      return tbl_concat(parts, " ")
    end
  end

  component.position = function()
    local content = "%l:%v"
    return highlight_fn(content, "position")
  end

  component.percentage = function()
    local _, mode_hl_key = content_builders.get_mode_content()
    return highlight_fn(" %P ", mode_hl_key)
  end

  return component
end

local function width_for(str)
  return fn.strdisplaywidth(str:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", ""))
end

local function assemble(parts, sep)
  local tbl = {}
  for _, part in ipairs(parts) do
    if part ~= "" then tbl_insert(tbl, part) end
  end
  return tbl_concat(tbl, sep)
end

local M = {}

local build_status = function(winid, opts)
  local bufnr = nvim_win_get_buf(winid)
  local c = create_components(winid, bufnr, opts.highlight)
  local sep = opts.highlight and apply_highlight(config.seps, "separator") or config.seps

  if not opts.enhanced then
    return "%=" .. (opts.inactive and c.inactive_filename() or c.simple_title()) .. "%="
  end

  local left = assemble({ c.mode(), c.directory(), c.git_branch() }, sep)
  local center = c.file_info()
  local right = assemble({ c.diagnostics(), c.lsp_status(), c.position(), c.percentage() }, sep)

  local w_left, w_right, w_center, w_win =
    width_for(left), width_for(right), width_for(center), nvim_win_get_width(winid)

  if (w_win - (w_left + w_right)) >= w_center + 4 then
    local gap = math.max(1, math.floor((w_win - w_center) / 2) - w_left)
    return left .. string.rep(" ", gap) .. center .. "%=" .. right
  end

  return assemble({ left, center, right }, "%=")
end

M.status = function(winid)
  local opts
  if is_excluded_buftype(winid) then
    opts = { highlight = true }
  elseif winid == nvim_get_current_win() then
    opts = { enhanced = true, highlight = true }
  else
    opts = { enhanced = true, inactive = true }
  end
  return build_status(winid, opts)
end

local function refresh(win)
  if win then
    refresh_win(win)
  else
    for _, w in ipairs(nvim_list_wins()) do refresh_win(w) end
  end
end

local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

local update_win_for_buf = function(buf, keys)
  for _, winid in ipairs(fn.win_findbuf(buf)) do
    cache_invalidate(get_win_data(winid).cache, keys)
    refresh_win(winid)
  end
end

autocmd("BufEnter", {
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

autocmd({ "BufWritePost", "BufFilePost" }, {
  group = group,
  callback = function(ev)
    update_win_for_buf(ev.buf, cache_keys.all)
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
