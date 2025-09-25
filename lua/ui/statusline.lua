local api, fn = vim.api, vim.fn
local autocmd = api.nvim_create_autocmd
local icons = require("ui.icons")

local separator = " • "
local excluded = {
  buftype = {
    terminal = icons.terminal .. " terminal",
  },
  filetype = {
    ["neo-tree"] = icons.file_tree .. " neo-tree",
    ["neo-tree-popup"] = icons.file_tree .. " neo-tree",
    qf = icons.fix .. " quickfix",
    checkhealth = icons.status .. " checkhealth",
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

local CacheMan = {}
CacheMan.__index = CacheMan

function CacheMan.new()
  return setmetatable({ cache = {} }, CacheMan)
end

function CacheMan:get(key, fnc)
  if self.cache[key] ~= nil then return self.cache[key] end
  local ok, res = pcall(fnc)
  self.cache[key] = ok and res or nil
  return self.cache[key]
end

function CacheMan:reset(keys)
  if type(keys) == "string" then
    self.cache[keys] = nil
  else
    for _, key in ipairs(keys) do self.cache[key] = nil end
  end
end

local win_data = setmetatable({}, { __mode = "k" })

local function get_win_cache(winid)
  local data = win_data[winid]
  if not data then
    data = { cache = CacheMan.new(), git = {}, icons = {} }
    win_data[winid] = data
  end
  return data.cache
end

local status_expr = "%%!v:lua.require'ui.statusline'.status(%d)"
local refresh_win = function(winid)
  if api.nvim_win_is_valid(winid) then
    vim.wo[winid].statusline = string.format(status_expr, winid)
    return
  end
  win_data[winid] = nil
end

local format_expr = "%%#%s#%s%%*"
local function hl_rule(content, hl, apply_hl)
  if not apply_hl or not hl or not content then return content or "" end
  return string.format(format_expr, hl, content)
end

local cmp = {}

local function register_cmp(name, render_fn, opts)
  opts = opts or {}
  cmp[name] = { render = render_fn, cache_keys = opts.cache_keys or {}, }
end

local function create_ctx(winid)
  local buf = api.nvim_win_get_buf(winid)
  local bo = vim.bo[buf]
  return {
    winid = winid,
    bufnr = buf,
    cache = get_win_cache(winid),
    windat = win_data[winid],
    filetype = bo.filetype,
    buftype = bo.buftype,
    readonly = bo.readonly,
    modified = bo.modified,
    mode_info = modes_tbl[api.nvim_get_mode().mode],
  }
end

local function render_cmp(name, ctx, apply_hl)
  local ok, result = pcall(cmp[name].render, ctx, apply_hl)
  return ok and result or ""
end

register_cmp("mode", function(ctx, apply_hl)
  return hl_rule(ctx.mode_info.text, ctx.mode_info.hl, apply_hl)
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
    if ctx.windat.git[cwd] == nil then
      ctx.windat.git[cwd] = false
      vim.system({ "git", "branch", "--show-current" }, { cwd = cwd, text = true, timeout = 1000 },
        vim.schedule_wrap(function(result)
          if not api.nvim_win_is_valid(ctx.winid) then return end
          local branch = (result.code == 0 and result.stdout) and result.stdout:gsub("%s*$", "") or ""
          ctx.windat.git[cwd] = branch
          ctx.cache:reset("git_branch")
          refresh_win(ctx.winid)
        end))
    end
    return ctx.windat.git[cwd] or ""
  end)
  if branch_name and branch_name ~= "" then
    return hl_rule(icons.git .. " " .. branch_name, "StatusLineGit", apply_hl)
  end
  return ""
end, { cache_keys = { "git_branch" } })

register_cmp("file_display", function(ctx, apply_hl)
  local file_data = ctx.cache:get("file_data", function()
    local name = api.nvim_buf_get_name(ctx.bufnr)
    local key = (name == "") and "[No Name]" or fn.fnamemodify(name, ":t")
    local ext = (name == "") and "" or fn.fnamemodify(name, ":e")
    if ctx.windat.icons[key] == nil then
      ctx.windat.icons[key] = { icon = "", hl = "Normal" }
      vim.schedule(function()
        if not api.nvim_win_is_valid(ctx.winid) then return end
        local ok, devicons = pcall(require, "nvim-web-devicons")
        if ok then
          local icon, hl = devicons.get_icon(key, ext)
          ctx.windat.icons[key] = {
            icon = icon or "",
            hl = hl or "Normal"
          }
          ctx.cache:reset("file_data")
          refresh_win(ctx.winid)
        end
      end)
    end
    local icon_info = ctx.windat.icons[key]
    return { name = key, icon = icon_info.icon, hl = icon_info.hl }
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
  local s = ctx.cache:get("file_status", function()
    return { readonly = ctx.readonly, modified = ctx.modified }
  end)
  return s.readonly and hl_rule(icons.readonly, "StatusLineReadonly", apply_hl) or
    s.modified and hl_rule(icons.modified, "StatusLineModified", apply_hl) or " "
end, { cache_keys = { "file_status" } })

register_cmp("simple_title", function(ctx, apply_hl)
  local title = excluded.buftype[ctx.buftype] or excluded.filetype[ctx.filetype]
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

register_cmp("percentage", function(ctx, apply_hl)
  return hl_rule(" %P ", ctx.mode_info.hl, apply_hl)
end)

local w_cache = setmetatable({}, { __mode = "k" })

local function get_width(s)
  if not s or s == "" then return 0 end
  if not w_cache[s] then
    w_cache[s] = fn.strdisplaywidth(s:gsub("%%#[^#]-#", ""):gsub("%%[*=<]", ""))
  end
  return w_cache[s]
end

local function build(parts, sep)
  local tbl = {}
  for _, part in ipairs(parts) do
    if part and part ~= "" then tbl[#tbl + 1] =  part end
  end
  return table.concat(tbl, sep)
end

local M = {}

M.status = function(winid)
  local ctx = create_ctx(winid)
  if excluded.buftype[ctx.buftype] or excluded.filetype[ctx.filetype] then
    return "%=" .. render_cmp("simple_title", ctx, true) .. "%="
  end
  local apply_hl = winid == api.nvim_get_current_win()
  local sep = hl_rule(separator, "StatusLineSeparator", apply_hl)
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
    refresh_win(api.nvim_get_current_win())
  end
})

autocmd("WinClosed", {
  group = group,
  callback = function(ev)
    local winid = tonumber(ev.match)
    if winid then win_data[winid] = nil end
  end,
})

return M
