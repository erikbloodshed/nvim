local api, fn = vim.api, vim.fn
local autocmd = api.nvim_create_autocmd
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

local hl_tbl = {
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

local titles_tbl = {
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
}

local diagnostics_tbl = {
  { icon = icons.error, hl_key = "diagnostic_error", severity_idx = 1 },
  { icon = icons.warn, hl_key = "diagnostic_warn", severity_idx = 2 },
  { icon = icons.info, hl_key = "diagnostic_info", severity_idx = 3 },
  { icon = icons.hint, hl_key = "diagnostic_hint", severity_idx = 4 },
}

local modes_tbl = {
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
}

setmetatable(modes_tbl, {
  __index = function()
    return { text = " ??? ", hl_key = "mode_normal" }
  end
})

local function cache_lookup(cache, key, fnc)
  local value = cache[key]
  if value ~= nil then return value end
  local ok, res = pcall(fnc)
  cache[key] = ok and res or ""
  return cache[key]
end

local function cache_clear(cache, keys)
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
  if not api.nvim_win_is_valid(win) then return false end
  local bufnr = api.nvim_win_get_buf(win)
  local bo = vim.bo[bufnr]
  local exclude = config.exclude
  return exclude.buftypes[bo.buftype] or exclude.filetypes[bo.filetype]
end

local status_expr = "%%!v:lua.require'ui.statusline'.status(%d)"

local function refresh_win(winid)
  if not api.nvim_win_is_valid(winid) then
    win_data[winid] = nil
    return
  end
  vim.wo[winid].statusline = string.format(status_expr, winid)
end

local function get_file_icon(winid, file)
  local icons_cache = get_win_data(winid).icons
  local cache_key = file.name .. "." .. (file.ext or "")
  local cached_value = icons_cache[cache_key]
  if cached_value ~= nil then
    return type(cached_value) == "table" and cached_value or { icon = "", hl = nil }
  end
  icons_cache[cache_key] = false
  vim.schedule(function()
    if not api.nvim_win_is_valid(winid) then return end
    local ok, icon_module = pcall(require, "nvim-web-devicons")
    local icon_result = { icon = "", hl = nil }
    if ok and icon_module then
      local icon, hl_group = icon_module.get_icon(file.name, file.ext)
      if icon then
        icon_result = { icon = icon, hl = hl_group }
      end
    end
    icons_cache[cache_key] = icon_result
    cache_clear(get_win_data(winid).cache, { "file_icon", "file_icon_plain" })
    refresh_win(winid)
  end)
  return { icon = "", hl = nil }
end

local function conditional_hl(content, hl_key, apply_hl)
  if not apply_hl or not hl_key then return content or "" end
  local hl_group = hl_tbl[hl_key] or hl_key
  if not hl_group or not content or content == "" then return content or "" end
  return string.format("%%#%s#%s%%*", hl_group, content)
end

local function get_file_info(bufnr)
  local name = api.nvim_buf_get_name(bufnr)
  local fname, ext = "[No Name]", ""
  if name ~= "" then
    fname, ext = fn.fnamemodify(name, ":t"), fn.fnamemodify(name, ":e")
  end
  return { name = fname, ext = ext, full_path = name }
end

local function create_components(winid, bufnr, apply_hl)
  local mode_info = modes_tbl[(api.nvim_get_mode() or {}).mode]
  local wdata = get_win_data(winid)
  local cache = wdata.cache
  local c = {}

  c.mode = function()
    local content, hl_key = mode_info.text, mode_info.hl_key
    return conditional_hl(content, hl_key, apply_hl)
  end

  c.directory = function()
    local cache_key = apply_hl and "directory" or "directory_plain"
    return cache_lookup(cache, cache_key, function()
      local buf_name = api.nvim_buf_get_name(bufnr)
      local full_path = (buf_name == "") and fn.getcwd() or fn.fnamemodify(buf_name, ":p:h")
      local display_name = fn.fnamemodify(full_path, ":~")
      if display_name and display_name ~= "" then
        local content = icons.folder .. " " .. display_name
        return conditional_hl(content, "directory", apply_hl)
      end
      return ""
    end)
  end

  c.git_branch = function()
    local cache_key = apply_hl and "git_branch" or "git_branch_plain"
    return cache_lookup(cache, cache_key, function()
      local buf_name = api.nvim_buf_get_name(bufnr)
      local cwd = buf_name ~= "" and fn.fnamemodify(buf_name, ":h") or fn.getcwd()
      local git_data = wdata.git
      if git_data[cwd] == nil then
        git_data[cwd] = false -- mark as fetching
        vim.system({ "git", "branch", "--show-current" },
          { cwd = cwd, text = true, timeout = 1000 },
          vim.schedule_wrap(function(result)
            if not api.nvim_win_is_valid(winid) then return end
            local branch_name = ""
            if result.code == 0 and result.stdout then
              branch_name = result.stdout:gsub("%s*$", "")
            end
            git_data[cwd] = branch_name
            cache_clear(cache, { "git_branch", "git_branch_plain" })
            refresh_win(winid)
          end))
        return ""
      end
      local branch_name = git_data[cwd]
      if type(branch_name) == "string" and branch_name ~= "" then
        return conditional_hl(icons.git .. " " .. branch_name, "git", apply_hl)
      end
      return ""
    end)
  end

  c.file_icon = function()
    local cache_key = apply_hl and "file_icon" or "file_icon_plain"
    return cache_lookup(cache, cache_key, function()
      local file_info = get_file_info(bufnr)
      local icon_data = get_file_icon(winid, file_info)
      return conditional_hl(icon_data.icon, icon_data.hl, apply_hl)
    end)
  end

  c.file_name = function()
    local cache_key = apply_hl and "file_name" or "file_name_plain"
    return cache_lookup(cache, cache_key, function()
      local file_info = get_file_info(bufnr)
      return conditional_hl(file_info.name, "file", apply_hl)
    end)
  end

  c.file_status = function()
    local cache_key = apply_hl and "file_status" or "file_status_plain"
    return cache_lookup(cache, cache_key, function()
      local bo = vim.bo[bufnr]
      if bo.readonly then
        return conditional_hl(icons.readonly, "readonly", apply_hl)
      elseif bo.modified then
        return conditional_hl(icons.modified, "modified", apply_hl)
      end
      return ""
    end)
  end

  c.simple_title = function()
    local bo = vim.bo[bufnr]
    local title_data = titles_tbl.buftype[bo.buftype] or
      titles_tbl.filetype[bo.filetype]
    local content, hl_key = title_data and title_data.text or "no file",
      title_data and title_data.hl_key or "simple_title"
    return conditional_hl(content, hl_key, apply_hl)
  end

  c.diagnostics = function()
    local cache_key = apply_hl and "diagnostics_hl" or "diagnostics_plain"
    return cache_lookup(cache, cache_key, function()
      local counts = vim.diagnostic.count(bufnr)
      if vim.tbl_isempty(counts) then
        return conditional_hl(icons.ok, "diagnostic_ok", apply_hl)
      end
      local parts = {}
      for _, diag_info in ipairs(diagnostics_tbl) do
        local count = counts[diag_info.severity_idx]
        if count and count > 0 then
          local content = string.format("%s:%d", diag_info.icon, count)
          parts[#parts + 1] = conditional_hl(content, diag_info.hl_key, apply_hl)
        end
      end
      return table.concat(parts, " ")
    end)
  end

  c.lsp_status = function()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if not clients or vim.tbl_isempty(clients) then return "" end
    local names = {}
    for _, client in ipairs(clients) do
      names[#names + 1] = client.name
    end
    local content = icons.lsp .. " " .. table.concat(names, ", ")
    return conditional_hl(content, "lsp", apply_hl)
  end

  c.position = function()
    return conditional_hl("%l:%v", "position", apply_hl)
  end

  c.percentage = function()
    return conditional_hl(" %P ", mode_info.hl_key, apply_hl)
  end

  return c
end

local width_cache = setmetatable({}, { __mode = "k" })

local function get_width(str)
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
    if part and part ~= "" then tbl[#tbl + 1] = part end
  end
  return table.concat(tbl, sep)
end

local M = {}

M.status = function(winid)
  local bufnr = api.nvim_win_get_buf(winid)
  if is_excluded_buftype(winid) then
    return "%=" .. create_components(winid, bufnr, true).simple_title() .. "%="
  end

  local apply_hl = winid == api.nvim_get_current_win()
  local c = create_components(winid, bufnr, apply_hl)
  local sep = conditional_hl(config.seps, "separator", apply_hl)

  local left = assemble({ c.mode(), c.directory(), c.git_branch() }, sep)
  local right = assemble({ c.diagnostics(), c.lsp_status(), c.position(), c.percentage() }, sep)
  local center = assemble({ c.file_icon(), c.file_name(), c.file_status() }, " ")

  local w_left, w_right, w_center, w_win =
    get_width(left), get_width(right), get_width(center), api.nvim_win_get_width(winid)

  if (w_win - (w_left + w_right)) >= w_center + 4 then
    local gap = math.max(1, math.floor((w_win - w_center) / 2) - w_left)
    return table.concat({ left, string.rep(" ", gap), center, "%=", right })
  end
  return table.concat({ left, center, right }, "%=")
end

local function refresh(win)
  if win then
    refresh_win(win)
  else
    for _, w in ipairs(api.nvim_list_wins()) do refresh_win(w) end
  end
end

local update_win = function(buf, keys)
  for _, winid in ipairs(fn.win_findbuf(buf)) do
    cache_clear(get_win_data(winid).cache, keys)
    refresh_win(winid)
  end
end

local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

autocmd({ "BufWinEnter", "BufWritePost" }, {
  group = group,
  callback = function(ev)
    update_win(ev.buf, {
      "file_icon", "file_icon_plain",
      "file_name", "file_name_plain",
      "file_status", "file_status_plain",
      "directory", "directory_plain",
      "git_branch", "git_branch_plain",
      "diagnostics_hl", "diagnostics_plain",
    })
  end,
})

autocmd("BufModifiedSet", {
  group = group,
  callback = function(ev)
    update_win(ev.buf, {
      "file_status", "file_status_plain",
    })
  end,
})

autocmd({ "BufFilePost", "BufNewFile" }, {
  group = group,
  callback = function(ev)
    update_win(ev.buf, {
      "file_icon", "file_icon_plain",
      "file_name", "file_name_plain",
    })
  end,
})

autocmd("DirChanged", {
  group = group,
  callback = function(ev)
    update_win(ev.buf, {
      "directory", "directory_plain",
      "git_branch", "git_branch_plain",
    })
  end,
})

autocmd("DiagnosticChanged", {
  group = group,
  callback = function(ev)
    update_win(ev.buf, {
      "diagnostics_hl", "diagnostics_plain",
    })
  end,
})

autocmd({ "VimResized", "WinResized" }, {
  group = group,
  callback = function() api.nvim_cmd({ cmd = "redrawstatus" }, {}) end,
})

autocmd({ "WinEnter" }, {
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
