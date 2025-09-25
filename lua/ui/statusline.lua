local api, fn = vim.api, vim.fn
local autocmd = api.nvim_create_autocmd
local icons = require("ui.icons")

local config = {
  seps = " • ",
  exclude = {
    buftypes = { terminal = true },
    filetypes = {
      ["neo-tree"] = true,
    },
  },
}

local titles_tbl = {
  buftype = { terminal = icons.terminal .. " terminal" },
  filetype = {
    ["neo-tree"] = icons.file_tree .. " File Explorer",
    ["neo-tree-popup"] = icons.file_tree .. " File Explorer",
  },
}

local diags_tbl = {
  { icon = icons.error, hl = "DiagnosticError", severity_idx = 1 },
  { icon = icons.warn, hl = "DiagnosticWarn", severity_idx = 2 },
  { icon = icons.info, hl = "DiagnosticInfo", severity_idx = 3 },
  { icon = icons.hint, hl = "DiagnosticHint", severity_idx = 4 },
}

local modes_tbl = {
  n = { text = " NOR ", hl = "StatusLineNormal" },
  i = { text = " INS ", hl = "StatusLineInsert" },
  v = { text = " VIS ", hl = "StatusLineVisual" },
  V = { text = " V-L ", hl = "StatusLineVisual" },
  ["\22"] = { text = " V-B ", hl = "StatusLineVisual" },
  s = { text = " SEL ", hl = "StatusLineSelect" },
  S = { text = " S-L ", hl = "StatusLineSelect" },
  ["\19"] = { text = " S-B ", hl = "StatusLineSelect" },
  r = { text = " REP ", hl = "StatusLineReplace" },
  R = { text = " REP ", hl = "StatusLineReplace" },
  Rv = { text = " R-V ", hl = "StatusLineReplace" },
  c = { text = " CMD ", hl = "StatusLineCommand" },
  __index = function() return { text = " ??? ", hl = "StatusLineNormal" } end,
}
setmetatable(modes_tbl, modes_tbl)

local CacheManager = {}
CacheManager.__index = CacheManager

function CacheManager.new()
  return setmetatable({ cache = {} }, CacheManager)
end

function CacheManager:get(key, fnc)
  if self.cache[key] ~= nil then return self.cache[key] end
  local ok, res = pcall(fnc)
  self.cache[key] = ok and res or nil
  return self.cache[key]
end

function CacheManager:reset(keys)
  if type(keys) == "string" then
    self.cache[keys] = nil
  else
    for _, key in ipairs(keys) do self.cache[key] = nil end
  end
end

local win_data = setmetatable({}, { __mode = "k" })

local function get_win_cache(winid)
  local d = win_data[winid]
  if not d then
    d = { cache = CacheManager.new(), git = {}, icons = {} }
    win_data[winid] = d
  end
  return d.cache
end

local function is_excluded_buftype(win)
  if not api.nvim_win_is_valid(win) then return false end
  local bo = vim.bo[api.nvim_win_get_buf(win)]
  return config.exclude.buftypes[bo.buftype] or config.exclude.filetypes[bo.filetype]
end

local status_expr = "%%!v:lua.require'ui.statusline'.status(%d)"

local function refresh_win(winid)
  if not api.nvim_win_is_valid(winid) then
    win_data[winid] = nil
    return
  end
  vim.wo[winid].statusline = string.format(status_expr, winid)
end

local function hl_rule(content, hl, apply_hl)
  if not apply_hl or not hl or not content or content == "" then return content or "" end
  return string.format("%%#%s#%s%%*", hl, content)
end

local cmp = {}

local function register_cmp(name, render_fn, opts)
  opts = opts or {}
  cmp[name] = {
    render = render_fn,
    cache_keys = opts.cache_keys or {},
  }
end

local function create_ctx(winid, bufnr)
  return {
    winid = winid,
    bufnr = bufnr,
    cache = get_win_cache(winid),
    wdata = win_data[winid],
    bo = vim.bo[bufnr],
  }
end

local function render_cmp(name, ctx, apply_hl)
  local c = cmp[name]
  local ok, result = pcall(c.render, ctx, apply_hl)
  if not ok then
    if vim.env.NVIM_DEBUG then
      vim.notify(string.format("Error in component '%s': %s", name, result), vim.log.levels.ERROR)
    end
    return ""
  end
  return result or ""
end

register_cmp("mode", function(_, apply_hl)
  local mode_info = modes_tbl[api.nvim_get_mode().mode]
  return hl_rule(mode_info.text, mode_info.hl, apply_hl)
end)

register_cmp("directory", function(ctx, apply_hl)
  local path = ctx.cache:get("directory", function()
    local buf_name = api.nvim_buf_get_name(ctx.bufnr)
    return (buf_name == "") and fn.getcwd() or fn.fnamemodify(buf_name, ":p:h")
  end)
  if not path or path == "" then return "" end
  local display_name = fn.fnamemodify(path, ":~")
  local content = icons.folder .. " " .. display_name
  return hl_rule(content, "Directory", apply_hl)
end, { cache_keys = { "directory" } })

register_cmp("git_branch", function(ctx, apply_hl)
  local branch_name = ctx.cache:get("git_branch", function()
    local cwd = fn.fnamemodify(api.nvim_buf_get_name(ctx.bufnr), ":h") or fn.getcwd()
    if ctx.wdata.git[cwd] == nil then
      ctx.wdata.git[cwd] = false
      vim.system({ "git", "branch", "--show-current" }, { cwd = cwd, text = true, timeout = 1000 },
        vim.schedule_wrap(function(result)
          if not api.nvim_win_is_valid(ctx.winid) then return end
          local branch = (result.code == 0 and result.stdout) and result.stdout:gsub("%s*$", "") or ""
          ctx.wdata.git[cwd] = branch
          ctx.cache:reset("git_branch")
          refresh_win(ctx.winid)
        end))
    end
    return ctx.wdata.git[cwd] or ""
  end)
  if branch_name and branch_name ~= "" then
    return hl_rule(icons.git .. " " .. branch_name, "StatusLineGit", apply_hl)
  end
  return ""
end, { cache_keys = { "git_branch" } })

register_cmp("file_display", function(ctx, apply_hl)
  local file_data = ctx.cache:get("file_data", function()
    local name = api.nvim_buf_get_name(ctx.bufnr)
    local fname = (name == "") and "[No Name]" or fn.fnamemodify(name, ":t")
    local ext = (name == "") and "" or fn.fnamemodify(name, ":e")
    local key = fname .. "." .. ext
    if ctx.wdata.icons[key] == nil then
      ctx.wdata.icons[key] = { icon = "", hl = "Normal" }
      vim.schedule(function()
        if not api.nvim_win_is_valid(ctx.winid) then return end
        local ok, devicons = pcall(require, "nvim-web-devicons")
        if ok then
          local icon, hl = devicons.get_icon(fname, ext)
          ctx.wdata.icons[key] = {
            icon = icon or "",
            hl = hl or "Normal"
          }
          ctx.cache:reset("file_data")
          refresh_win(ctx.winid)
        end
      end)
    end
    local icon_info = ctx.wdata.icons[key]
    return {
      name = fname,
      icon = icon_info.icon,
      hl = icon_info.hl
    }
  end)
  local parts = {}
  if file_data.icon and file_data.icon ~= "" then
    parts[#parts + 1] = hl_rule(file_data.icon, file_data.hl, apply_hl)
    parts[#parts + 1] = " "
  end
  parts[#parts + 1] = hl_rule(file_data.name, "StatusLine", apply_hl)
  return table.concat(parts, "")
end, { cache_keys = { "file_data" } })

register_cmp("file_status", function(ctx, apply_hl)
  local status = ctx.cache:get("file_status", function()
    return { readonly = ctx.bo.readonly, modified = ctx.bo.modified }
  end)
  if status.readonly then
    return hl_rule(icons.readonly, "StatusLineReadonly", apply_hl)
  elseif status.modified then
    return hl_rule(icons.modified, "StatusLineModified", apply_hl)
  end
  return " "
end, { cache_keys = { "file_status" } })

register_cmp("simple_title", function(ctx, apply_hl)
  local title = titles_tbl.buftype[ctx.bo.buftype] or titles_tbl.filetype[ctx.bo.filetype]
  return hl_rule(title or "no file", "String", apply_hl)
end)

register_cmp("diagnostics", function(ctx, apply_hl)
  local counts = ctx.cache:get("diagnostics", function()
    return vim.diagnostic.count(ctx.bufnr)
  end)
  if not counts or vim.tbl_isempty(counts) then
    return hl_rule(icons.ok, "DiagnosticOk", apply_hl)
  end
  local parts = {}
  for _, diag in ipairs(diags_tbl) do
    local count = counts[diag.severity_idx]
    if count and count > 0 then
      parts[#parts + 1] = hl_rule(string.format("%s:%d", diag.icon, count), diag.hl, apply_hl)
    end
  end
  return table.concat(parts, " ")
end, { cache_keys = { "diagnostics" } })

register_cmp("lsp_status", function(ctx, apply_hl)
  local clients = ctx.cache:get("lsp_clients", function()
    return vim.lsp.get_clients({ bufnr = ctx.bufnr })
  end)
  if not clients or vim.tbl_isempty(clients) then return "" end
  local names = {}
  for _, client in ipairs(clients) do names[#names + 1] = client.name end
  local content = icons.lsp .. " " .. table.concat(names, ", ")
  return hl_rule(content, "StatusLineLsp", apply_hl)
end, { cache_keys = { "lsp_clients" } })

register_cmp("position", function(_, apply_hl)
  return hl_rule("%l:%v", "StatusLineValue", apply_hl)
end)

register_cmp("percentage", function(_, apply_hl)
  local mode_info = modes_tbl[api.nvim_get_mode().mode]
  return hl_rule(" %P ", mode_info.hl, apply_hl)
end)

local width_cache = setmetatable({}, { __mode = "k" })

local function get_width(str)
  if not str or str == "" then return 0 end
  if width_cache[str] then return width_cache[str] end
  local cleaned = str:gsub("%%#[^#]*#", ""):gsub("%%[*=<]", "")
  local width = fn.strdisplaywidth(cleaned)
  width_cache[str] = width
  return width
end

local function build(parts, sep)
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
    local ctx = create_ctx(winid, bufnr)
    return "%=" .. render_cmp("simple_title", ctx, true) .. "%="
  end
  local apply_hl = winid == api.nvim_get_current_win()
  local ctx = create_ctx(winid, bufnr)
  local sep = hl_rule(config.seps, "StatusLineSeparator", apply_hl)
  local left = build({
    render_cmp("mode", ctx, apply_hl),
    render_cmp("directory", ctx, apply_hl),
    render_cmp("git_branch", ctx, apply_hl),
  }, sep)
  local right = build({
    render_cmp("diagnostics", ctx, apply_hl),
    render_cmp("lsp_status", ctx, apply_hl),
    render_cmp("position", ctx, apply_hl),
    render_cmp("percentage", ctx, apply_hl),
  }, sep)
  local center = build({
    render_cmp("file_display", ctx, apply_hl),
    render_cmp("file_status", ctx, apply_hl),
  }, " ")
  local w_left, w_right, w_center, w_win = get_width(left), get_width(right), get_width(center),
    api.nvim_win_get_width(winid)
  if (w_win - (w_left + w_right)) >= w_center + 4 then
    local gap = math.max(1, math.floor((w_win - w_center) / 2) - w_left)
    return table.concat({ left, string.rep(" ", gap), center, "%=", right })
  end
  return table.concat({ left, center, right }, "%=")
end

local function reload(buf, keys)
  for _, winid in ipairs(fn.win_findbuf(buf)) do
    if win_data[winid] then
      get_win_cache(winid):reset(keys)
    end
    refresh_win(winid)
  end
end

local keys = { "file_data", "file_status", "directory", "git_branch", "diagnostics", "lsp_clients" }
local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

autocmd({ "BufWinEnter", "BufWritePost" }, {
  group = group,
  callback = function(ev) reload(ev.buf, keys) end,
})

autocmd("BufModifiedSet", {
  group = group,
  callback = function(ev) reload(ev.buf, "file_status") end,
})

autocmd("DirChanged", {
  group = group,
  callback = function(ev) reload(ev.buf, { "directory", "git_branch" }) end,
})

autocmd("DiagnosticChanged", {
  group = group,
  callback = function(ev) reload(ev.buf, "diagnostics") end,
})

autocmd({ "LspAttach", "LspDetach" }, {
  group = group,
  callback = function(ev) reload(ev.buf, "lsp_clients") end,
})

autocmd({ "VimResized", "WinResized" }, {
  group = group,
  callback = function() api.nvim_cmd({ cmd = "redrawstatus" }, {}) end,
})

autocmd({ "WinEnter", "WinLeave" }, {
  group = group,
  callback = function()
    for _, w in ipairs(api.nvim_list_wins()) do refresh_win(w) end
  end,
})

autocmd("WinClosed", {
  group = group,
  callback = function(ev)
    local winid = tonumber(ev.match)
    if winid then win_data[winid] = nil end
  end,
})

return M
