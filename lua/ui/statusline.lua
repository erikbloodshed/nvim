local api, fn = vim.api, vim.fn
local icons = require("ui.icons")

local M = {}

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
local tbl_filter = vim.tbl_filter
local tbl_isempty = vim.tbl_isempty

local x = vim.diagnostic.severity
local sev_map = {
  [x.ERROR] = { "DiagnosticError", icons.error },
  [x.WARN] = { "DiagnosticWarn", icons.warn },
  [x.INFO] = { "DiagnosticInfo", icons.info },
  [x.HINT] = { "DiagnosticHint", icons.hint },
}

local HL_FORMAT = "%%#%s#%s%%*"
local STATUS_EXPR_SIMPLE = '%%!v:lua.require("ui.statusline").status_simple(%d)'
local STATUS_EXPR_ADVANCED = '%%!v:lua.require("ui.statusline").status_advanced(%d)'
local STATUS_EXPR_INACTIVE = '%%!v:lua.require("ui.statusline").status_inactive(%d)'

local component_pool = {
  diagnostics = {},
  mode = {},
  lsp_status = {},
  file_info = {},
  git_branch = {},
  directory = {},
  pool_size = 15,
}

local pooled_component = {
  parts = {},
  text = "",
  width = 0,
  icon = "",
  name = "",
  status = "",
  highlight = "",
}

local get_pooled_component = function(type_name)
  local pool = component_pool[type_name]
  if pool and type(pool) == "table" and #pool > 0 then
    return table.remove(pool)
  end
  return pooled_component
end

local return_to_pool = function(type_name, component)
  if not component then return end

  local pool = component_pool[type_name]
  if not pool or type(pool) ~= "table" then
    pool = {}
    component_pool[type_name] = pool
  end

  local pool_size = component_pool.pool_size
  if type(pool_size) == "number" and #pool < pool_size then
    component.text = ""
    component.width = 0
    component.icon = ""
    component.name = ""
    component.status = ""
    component.highlight = ""

    if component.parts then
      for i = #component.parts, 1, -1 do
        component.parts[i] = nil
      end
    end

    tbl_insert(pool, component)
  end
end

local cache_new = function()
  return {
    data = {},
    widths = {},
  }
end

local cache_update = function(cache, key, value)
  cache.data[key] = value
  if type(value) == "string" then
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

local win_caches = setmetatable({}, { __mode = "k" })
local win_git_data = setmetatable({}, { __mode = "k" })
local win_file_icon_data = setmetatable({}, { __mode = "k" })

local get_win_cache = function(winid)
  return win_caches[winid] or cache_new()
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
  return strformat(HL_FORMAT, name, text)
end

local loaded = {}

local safe_require = function(mod)
  local cached = loaded[mod]
  if cached ~= nil then return cached end
  local ok, res = pcall(require, mod)
  loaded[mod] = ok and res or false
  return loaded[mod]
end

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
  local props = get_buf_props(nvim_win_get_buf(win))
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
    expr = strformat(STATUS_EXPR_SIMPLE, winid)
  elseif is_active then
    expr = strformat(STATUS_EXPR_ADVANCED, winid)
  else
    expr = strformat(STATUS_EXPR_INACTIVE, winid)
  end

  vim.wo[winid].statusline = expr
end

local get_file_icon = function(winid, filename, extension, use_colors)
  local file_icon_cache = win_file_icon_data[winid]
  if not file_icon_cache then
    file_icon_cache = {}
    win_file_icon_data[winid] = file_icon_cache
  end

  local cache_key = strformat("%s.%s%s", filename, extension or "", use_colors and "_c" or "_p")
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

local HL_READONLY = " " .. hl("StatusLineReadonly", icons.readonly)
local HL_MODIFIED = " " .. hl("StatusLineModified", icons.modified)

local create_components = function(winid, bufnr)
  local cache = get_win_cache(winid)
  local component = {}

  component.mode = function()
    return cache_lookup(cache, "mode", function()
      local mode_comp = get_pooled_component("mode")

      local mode = (nvim_get_mode() or {}).mode
      local m = modes[mode] or { " ? ", "StatusLineNormal" }

      mode_comp.text = hl(m[2], m[1])
      mode_comp.highlight = m[2]
      mode_comp.name = m[1]

      local result = mode_comp.text
      return_to_pool("mode", mode_comp)
      return result
    end)
  end

  component.file_parts = function()
    return cache_lookup(cache, "file_parts", function()
      local name = nvim_buf_get_name(bufnr)
      if name == "" then
        return { filename = "[No Name]", extension = "" }
      end
      local filename = fn.fnamemodify(name, ":t")
      local extension = fn.fnamemodify(filename, ":e")
      return { filename = filename, extension = extension }
    end)
  end

  component.file_info = function()
    return cache_lookup(cache, "file_info", function()
      local file_comp = get_pooled_component("file_info")

      local parts = component.file_parts()
      file_comp.icon = get_file_icon(winid, parts.filename, parts.extension, true)
      file_comp.name = parts.filename

      local props = get_buf_props(bufnr)
      file_comp.status = props.readonly and HL_READONLY or
        props.modified and HL_MODIFIED or ""

      local file_part = hl("StatusLineFile", file_comp.icon .. file_comp.name)
      file_comp.text = file_part .. file_comp.status

      local result = file_comp.text
      return_to_pool("file_info", file_comp)
      return result
    end)
  end

  component.inactive_filename = function()
    return cache_lookup(cache, "inactive_filename", function()
      local parts = component.file_parts()
      local icon = get_file_icon(winid, parts.filename, parts.extension, false)
      local props = get_buf_props(bufnr)
      local status_flag = props.readonly and " " .. icons.readonly or
        props.modified and " " .. icons.modified or ""
      return string.format("%s%s%s", icon, parts.filename, status_flag)
    end)
  end

  component.simple_title = function()
    return cache_lookup(cache, "simple_title", function()
      local props = get_buf_props(bufnr)

      local title_map = {
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

      local title = title_map.buftype[props.buftype] or
        title_map.filetype[props.filetype] or "no file"

      return hl("String", title)
    end)
  end

  component.git_branch = function()
    return cache_lookup(cache, "git_branch", function()
      local git_comp = get_pooled_component("git_branch")

      local buf_name = nvim_buf_get_name(bufnr)
      local buf_dir = buf_name ~= "" and fn.fnamemodify(buf_name, ":h") or fn.getcwd()
      local gitdir = vim.fs.find({ ".git" }, { upward = true, path = buf_dir })

      if not gitdir or not gitdir[1] then
        return_to_pool("git_branch", git_comp)
        return ""
      end

      local root = vim.fs.dirname(gitdir[1])
      local git_data = win_git_data[winid]
      if not git_data then
        git_data = {}
        win_git_data[winid] = git_data
      end

      local cached_value = git_data[root]

      if type(cached_value) == "string" then
        return_to_pool("git_branch", git_comp)
        return cached_value
      end

      if cached_value == false then
        return_to_pool("git_branch", git_comp)
        return ""
      end

      git_data[root] = false
      vim.schedule(function() fetch_git_branch(winid, root) end)

      return_to_pool("git_branch", git_comp)
      return ""
    end)
  end

  component.directory = function()
    return cache_lookup(cache, "directory", function()
      local dir_comp = get_pooled_component("directory")

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
        dir_comp.text = hl("Directory", icons.folder .. " " .. display_name)
        dir_comp.name = display_name
      else
        dir_comp.text = ""
      end

      local result = dir_comp.text
      return_to_pool("directory", dir_comp)
      return result
    end)
  end

  component.diagnostics = function()
    return cache_lookup(cache, "diagnostics", function()
      local diag_comp = get_pooled_component("diagnostics")
      local counts = vim.diagnostic.count(bufnr)

      if tbl_isempty(counts) then
        diag_comp.text = hl("DiagnosticOk", icons.ok)
      else
        for severity, opts in ipairs(sev_map) do
          local count = counts[severity]
          if count and count > 0 then
            tbl_insert(diag_comp.parts, hl(opts[1], opts[2] .. ":" .. count))
          end
        end
        diag_comp.text = tbl_concat(diag_comp.parts, " ")
      end

      local result = diag_comp.text
      return_to_pool("diagnostics", diag_comp)
      return result
    end)
  end

  component.lsp_status = function()
    return cache_lookup(cache, "lsp_status", function()
      local lsp_comp = get_pooled_component("lsp_status")
      local clients = vim.lsp.get_clients({ bufnr = bufnr })

      if not clients or #clients == 0 then
        return_to_pool("lsp_status", lsp_comp)
        return ""
      end

      for i = 1, #clients do
        tbl_insert(lsp_comp.parts, clients[i].name)
      end

      lsp_comp.text = hl("StatusLineLsp", icons.lsp .. " " .. tbl_concat(lsp_comp.parts, ", "))

      local result = lsp_comp.text
      return_to_pool("lsp_status", lsp_comp)
      return result
    end)
  end

  return component
end

local width_for = function(cache, key_or_str)
  local width = cache.widths[key_or_str]
  if width then return width end

  if type(key_or_str) == "string" then
    return fn.strdisplaywidth(key_or_str:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", ""))
  end
  return 0
end

M.status_simple = function(winid)
  if not nvim_win_is_valid(winid) then return "" end
  local components = create_components(winid, nvim_win_get_buf(winid))
  return "%=" .. components.simple_title() .. "%="
end

M.status_inactive = function(winid)
  if not nvim_win_is_valid(winid) then return "" end
  local bufnr = nvim_win_get_buf(winid)
  local components = create_components(winid, bufnr)
  local center = components.inactive_filename()
  return "%=" .. center .. "%="
end

local POS_FORMAT = tbl_concat({
  hl("StatusLineLabel", "Ln "), hl("StatusLineValue", "%l"),
  hl("StatusLineLabel", ", Col "), hl("StatusLineValue", "%v") })
local PERCENT_FORMAT = hl("StatusLineValue", "%P")
local SEP = hl("StatusLineSeparator", config.seps.section)

local filter = function(v) return v ~= "" end

M.status_advanced = function(winid)
  if not nvim_win_is_valid(winid) then return "" end
  local bufnr = nvim_win_get_buf(winid)
  local cache = get_win_cache(winid)
  local components = create_components(winid, bufnr)

  local left = tbl_concat(tbl_filter(filter, {
    components.mode(), components.directory(), components.git_branch()
  }), " ")

  local right = tbl_concat(tbl_filter(filter, {
    components.diagnostics(), components.lsp_status(), POS_FORMAT, PERCENT_FORMAT
  }), SEP)

  local center = components.file_info()
  local w_left = width_for(cache, left)
  local w_right = width_for(cache, right)
  local w_center = cache.widths.file_info or width_for(cache, center)
  local w_win = nvim_win_get_width(winid)

  if (w_win - (w_left + w_right)) >= w_center + 4 then
    local gap = math.max(1, math.floor((w_win - w_center) / 2) - w_left)
    return strformat("%s%s%s%%=%s", left, string.rep(" ", gap), center, right)
  end

  return tbl_concat({ left, center, right }, "%=")
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
      { "git_branch", "file_parts", "file_info", "directory", "lsp_status",
        "diagnostics", "inactive_filename" })
    refresh_win(winid)
  end
})

local update_win_for_buf = function(buf, cache_keys)
  for _, winid in ipairs(nvim_list_wins()) do
    if nvim_win_get_buf(winid) == buf then
      cache_invalidate(get_win_cache(winid), cache_keys)
      refresh_win(winid)
    end
  end
end

autocmd("BufModifiedSet", {
  group = group,
  callback = function(ev)
    buf_cache[ev.buf] = nil
    update_win_for_buf(ev.buf, { "file_info", "inactive_filename" })
  end
})

autocmd({ "LspAttach", "LspDetach" }, {
  group = group,
  callback = function(ev)
    update_win_for_buf(ev.buf, "lsp_status")
  end
})

autocmd({ "DiagnosticChanged" }, {
  group = group,
  callback = function(ev)
    update_win_for_buf(ev.buf, "diagnostics")
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

autocmd({ "BufWritePost", "FileType", "BufReadPost" }, {
  group = group,
  callback = function(ev)
    buf_cache[ev.buf] = nil
  end
})

return M
