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

local titles_tbl = {
  buftype = {
    terminal = icons.terminal .. " terminal",
    popup = icons.dock .. " Popup",
  },
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

local diagnostics_tbl = {
  { icon = icons.error, hl_key = "DiagnosticError", severity_idx = 1 },
  { icon = icons.warn, hl_key = "DiagnosticWarn", severity_idx = 2 },
  { icon = icons.info, hl_key = "DiagnosticInfo", severity_idx = 3 },
  { icon = icons.hint, hl_key = "DiagnosticHint", severity_idx = 4 },
}

local modes_tbl = {
  n = { text = " NOR ", hl_key = "StatusLineNormal" },
  i = { text = " INS ", hl_key = "StatusLineInsert" },
  v = { text = " VIS ", hl_key = "StatusLineVisual" },
  V = { text = " V-L ", hl_key = "StatusLineVisual" },
  ["\22"] = { text = " V-B ", hl_key = "StatusLineVisual" },
  s = { text = " SEL ", hl_key = "StatusLineSelect" },
  S = { text = " S-L ", hl_key = "StatusLineSelect" },
  ["\19"] = { text = " S-B ", hl_key = "StatusLineSelect" },
  r = { text = " REP ", hl_key = "StatusLineReplace" },
  R = { text = " REP ", hl_key = "StatusLineReplace" },
  Rv = { text = " R-V ", hl_key = "StatusLineReplace" },
  c = { text = " CMD ", hl_key = "StatusLineCommand" },
}

setmetatable(modes_tbl, {
  __index = function()
    return { text = " ??? ", hl_key = "StatusLineNormal" }
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
  local bo = vim.bo[api.nvim_win_get_buf(win)]
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

local function conditional_hl(content, hl_key, apply_hl)
  if not apply_hl or not hl_key or not content or content == "" then
    return content or ""
  end
  return string.format("%%#%s#%s%%*", hl_key, content)
end

local function get_file_info(bufnr)
  local name = api.nvim_buf_get_name(bufnr)
  local fname, ext = "[No Name]", ""
  if name ~= "" then
    fname, ext = fn.fnamemodify(name, ":t"), fn.fnamemodify(name, ":e")
  end
  return { name = fname, ext = ext, full_path = name }
end

local function refresh_keys(winid, keys)
  cache_clear(get_win_data(winid).cache, keys)
  refresh_win(winid)
end

local function create_components(winid, bufnr, apply_hl)
  local mode_info = modes_tbl[(api.nvim_get_mode() or {}).mode]
  local wdata = get_win_data(winid)
  local cache = wdata.cache
  local C = {}

  C.mode = function()
    local content, hl_key = mode_info.text, mode_info.hl_key
    return conditional_hl(content, hl_key, apply_hl)
  end

  C.directory = function()
    local cache_key = apply_hl and "directory" or "directory_plain"
    return cache_lookup(cache, cache_key, function()
      local buf_name = api.nvim_buf_get_name(bufnr)
      local full_path = (buf_name == "") and fn.getcwd() or fn.fnamemodify(buf_name, ":p:h")
      local display_name = fn.fnamemodify(full_path, ":~")
      if display_name and display_name ~= "" then
        local content = icons.folder .. " " .. display_name
        return conditional_hl(content, "Directory", apply_hl)
      end
      return ""
    end)
  end

  C.git_branch = function()
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
            refresh_keys(winid, { "git_branch", "git_branch_plain" })
          end))
        return ""
      end
      local branch_name = git_data[cwd]
      if type(branch_name) == "string" and branch_name ~= "" then
        return conditional_hl(icons.git .. " " .. branch_name, "StatusLineGit", apply_hl)
      end
      return ""
    end)
  end

  C.file_icon = function()
    local cache_key = apply_hl and "file_icon" or "file_icon_plain"
    return cache_lookup(cache, cache_key, function()
      local file_info = get_file_info(bufnr)
      local icons_cache = get_win_data(winid).icons
      local key = file_info.name .. "." .. (file_info.ext or "")
      local cached_value = icons_cache[key]

      if cached_value ~= nil then
        local icon_data = type(cached_value) == "table" and cached_value or { icon = "", hl = nil }
        return conditional_hl(icon_data.icon, icon_data.hl, apply_hl)
      end

      icons_cache[key] = false
      vim.schedule(function()
        if not api.nvim_win_is_valid(winid) then return end
        local ok, icon_module = pcall(require, "nvim-web-devicons")
        local icon_result = { icon = "", hl = nil }
        if ok and icon_module then
          local icon, hl_group = icon_module.get_icon(file_info.name, file_info.ext)
          if icon then
            icon_result = { icon = icon, hl = hl_group }
          end
        end
        icons_cache[key] = icon_result
        refresh_keys(winid, { "file_icon", "file_icon_plain" })
      end)

      return conditional_hl("", nil, apply_hl)
    end)
  end

  C.file_name = function()
    local cache_key = apply_hl and "file_name" or "file_name_plain"
    return cache_lookup(cache, cache_key, function()
      local file_info = get_file_info(bufnr)
      return conditional_hl(file_info.name, "StatusLineFile", apply_hl)
    end)
  end

  C.file_status = function()
    local cache_key = apply_hl and "file_status" or "file_status_plain"
    return cache_lookup(cache, cache_key, function()
      local bo = vim.bo[bufnr]
      if bo.readonly then
        return conditional_hl(icons.readonly, "StatusLineReadonly", apply_hl)
      elseif bo.modified then
        return conditional_hl(icons.modified, "StatusLineModified", apply_hl)
      end
      return " "
    end)
  end

  C.simple_title = function()
    local bo = vim.bo[bufnr]
    local title = titles_tbl.buftype[bo.buftype] or titles_tbl.filetype[bo.filetype]
    local content = title or "no file"
    return conditional_hl(content, "String", apply_hl)
  end

  C.diagnostics = function()
    local cache_key = apply_hl and "diagnostics_hl" or "diagnostics_plain"
    return cache_lookup(cache, cache_key, function()
      local counts = vim.diagnostic.count(bufnr)
      if vim.tbl_isempty(counts) then
        return conditional_hl(icons.ok, "DiagnosticOk", apply_hl)
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

  C.lsp_status = function()
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if not clients or vim.tbl_isempty(clients) then return "" end
    local names = {}
    for _, client in ipairs(clients) do
      names[#names + 1] = client.name
    end
    local content = icons.lsp .. " " .. table.concat(names, ", ")
    return conditional_hl(content, "StatusLineLsp", apply_hl)
  end

  C.position = function()
    return conditional_hl("%l:%v", "StatusLineValue", apply_hl)
  end

  C.percentage = function()
    return conditional_hl(" %P ", mode_info.hl_key, apply_hl)
  end

  return C
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
  local sep = conditional_hl(config.seps, "StatusLineSeparator", apply_hl)
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
    refresh_keys(winid, keys)
  end
end

local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

local cache_keys = {
  all = {
    "file_icon", "file_icon_plain",
    "file_name", "file_name_plain",
    "file_status", "file_status_plain",
    "directory", "directory_plain",
    "git_branch", "git_branch_plain",
    "diagnostics_hl", "diagnostics_plain",
  },
  file_status = {
    "file_status", "file_status_plain",
  },
  directory = {
    "directory", "directory_plain",
    "git_branch", "git_branch_plain",
  },
  diagnostics = {
    "diagnostics_hl", "diagnostics_plain",
  }
}

autocmd({ "BufWinEnter", "BufWritePost" }, {
  group = group,
  callback = function(ev)
    update_win(ev.buf, cache_keys.all)
  end,
})

autocmd("BufModifiedSet", {
  group = group,
  callback = function(ev)
    update_win(ev.buf, cache_keys.file_status)
  end,
})

autocmd("DirChanged", {
  group = group,
  callback = function(ev)
    update_win(ev.buf, cache_keys.directory)
  end,
})

autocmd("DiagnosticChanged", {
  group = group,
  callback = function(ev)
    update_win(ev.buf, cache_keys.diagnostics)
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
