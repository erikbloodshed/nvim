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
      man = true,
      qf = true,
    },
  },
  sections = {
    left = { "mode", "directory", "git_branch" },
    center = { "file_display", "file_status" },
    right = { "diagnostics", "lsp_status", "position", "percentage" },
  },
  separators = {
    left = " • ",
    center = " ",
    right = " • ",
  },
}

local function setup(user_config)
  config = vim.tbl_deep_extend("force", config, user_config or {})
end

local titles_tbl = {
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

local diagnostics_tbl = {
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

function CacheManager:invalidate(keys)
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

local function conditional_hl(content, hl, apply_hl)
  if not apply_hl or not hl or not content or content == "" then return content or "" end
  return string.format("%%#%s#%s%%*", hl, content)
end

local components = {}

local function register_component(name, render_fn, opts)
  opts = opts or {}
  components[name] = {
    render = render_fn,
    cache_keys = opts.cache_keys or {},
    enabled = opts.enabled ~= false,
    priority = opts.priority or 0,
  }
end

local function create_context(winid, bufnr)
  return {
    winid = winid,
    bufnr = bufnr,
    cache = get_win_cache(winid),
    wdata = win_data[winid],
    bo = vim.bo[bufnr],
  }
end

local function render_component(name, ctx, apply_hl)
  local component = components[name]
  if not component or not component.enabled then return "" end
  local ok, result = pcall(component.render, ctx, apply_hl)
  if not ok then
    if vim.env.NVIM_DEBUG then
      vim.notify(string.format("Error in component '%s': %s", name, result), vim.log.levels.ERROR)
    end
    return ""
  end
  return result or ""
end

register_component("mode", function(_, apply_hl)
  local mode_info = modes_tbl[api.nvim_get_mode().mode]
  return conditional_hl(mode_info.text, mode_info.hl, apply_hl)
end)

register_component("directory", function(ctx, apply_hl)
  local path = ctx.cache:get("directory", function()
    local buf_name = api.nvim_buf_get_name(ctx.bufnr)
    return (buf_name == "") and fn.getcwd() or fn.fnamemodify(buf_name, ":p:h")
  end)
  if not path or path == "" then return "" end
  local display_name = fn.fnamemodify(path, ":~")
  local content = icons.folder .. " " .. display_name
  return conditional_hl(content, "Directory", apply_hl)
end, { cache_keys = { "directory" } })

register_component("git_branch", function(ctx, apply_hl)
  local branch_name = ctx.cache:get("git_branch", function()
    local cwd = fn.fnamemodify(api.nvim_buf_get_name(ctx.bufnr), ":h") or fn.getcwd()
    if ctx.wdata.git[cwd] == nil then
      ctx.wdata.git[cwd] = false
      vim.system({ "git", "branch", "--show-current" }, { cwd = cwd, text = true, timeout = 1000 },
        vim.schedule_wrap(function(result)
          if not api.nvim_win_is_valid(ctx.winid) then return end
          local branch = (result.code == 0 and result.stdout) and result.stdout:gsub("%s*$", "") or ""
          ctx.wdata.git[cwd] = branch
          ctx.cache:invalidate("git_branch")
          refresh_win(ctx.winid)
        end))
    end
    return ctx.wdata.git[cwd] or ""
  end)
  if branch_name and branch_name ~= "" then
    return conditional_hl(icons.git .. " " .. branch_name, "StatusLineGit", apply_hl)
  end
  return ""
end, { cache_keys = { "git_branch" } })

register_component("file_display", function(ctx, apply_hl)
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
          ctx.cache:invalidate("file_data")
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
    parts[#parts + 1] = conditional_hl(file_data.icon, file_data.hl, apply_hl)
    parts[#parts + 1] = " "
  end
  parts[#parts + 1] = conditional_hl(file_data.name, "StatusLine", apply_hl)
  return table.concat(parts, "")
end, { cache_keys = { "file_data" } })

register_component("file_status", function(ctx, apply_hl)
  local status = ctx.cache:get("file_status", function()
    return { readonly = ctx.bo.readonly, modified = ctx.bo.modified }
  end)
  if status.readonly then
    return conditional_hl(icons.readonly, "StatusLineReadonly", apply_hl)
  elseif status.modified then
    return conditional_hl(icons.modified, "StatusLineModified", apply_hl)
  end
  return " "
end, { cache_keys = { "file_status" } })

register_component("simple_title", function(ctx, apply_hl)
  local title = titles_tbl.buftype[ctx.bo.buftype] or titles_tbl.filetype[ctx.bo.filetype]
  return conditional_hl(title or "no file", "String", apply_hl)
end)

register_component("diagnostics", function(ctx, apply_hl)
  local counts = ctx.cache:get("diagnostics", function()
    return vim.diagnostic.count(ctx.bufnr)
  end)
  if not counts or vim.tbl_isempty(counts) then
    return conditional_hl(icons.ok, "DiagnosticOk", apply_hl)
  end
  local parts = {}
  for _, diag in ipairs(diagnostics_tbl) do
    local count = counts[diag.severity_idx]
    if count and count > 0 then
      parts[#parts + 1] = conditional_hl(string.format("%s:%d", diag.icon, count), diag.hl, apply_hl)
    end
  end
  return table.concat(parts, " ")
end, { cache_keys = { "diagnostics" } })

register_component("lsp_status", function(ctx, apply_hl)
  local clients = ctx.cache:get("lsp_clients", function()
    return vim.lsp.get_clients({ bufnr = ctx.bufnr })
  end)
  if not clients or vim.tbl_isempty(clients) then return "" end
  local names = {}
  for _, client in ipairs(clients) do names[#names + 1] = client.name end
  local content = icons.lsp .. " " .. table.concat(names, ", ")
  return conditional_hl(content, "StatusLineLsp", apply_hl)
end, { cache_keys = { "lsp_clients" } })

register_component("position", function(_, apply_hl)
  return conditional_hl("%l:%v", "StatusLineValue", apply_hl)
end)

register_component("percentage", function(_, apply_hl)
  local mode_info = modes_tbl[api.nvim_get_mode().mode]
  return conditional_hl(" %P ", mode_info.hl, apply_hl)
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

local function assemble(parts, sep)
  local tbl = {}
  for _, part in ipairs(parts) do
    if part and part ~= "" then tbl[#tbl + 1] = part end
  end
  return table.concat(tbl, sep)
end

-- Helper function to render a section based on configuration
local function render_section(section_name, ctx, apply_hl)
  local components_list = config.sections[section_name]
  if not components_list or vim.tbl_isempty(components_list) then return "" end

  local parts = {}
  for _, component_name in ipairs(components_list) do
    parts[#parts + 1] = render_component(component_name, ctx, apply_hl)
  end

  local separator = config.separators[section_name] or config.seps
  return assemble(parts, separator)
end

local M = {}

-- Expose setup function
M.setup = setup

M.status = function(winid)
  local bufnr = api.nvim_win_get_buf(winid)
  if is_excluded_buftype(winid) then
    local ctx = create_context(winid, bufnr)
    return "%=" .. render_component("simple_title", ctx, true) .. "%="
  end

  local apply_hl = winid == api.nvim_get_current_win()
  local ctx = create_context(winid, bufnr)

  local left = render_section("left", ctx, apply_hl)
  local center = render_section("center", ctx, apply_hl)
  local right = render_section("right", ctx, apply_hl)

  local w_left, w_right, w_center, w_win = get_width(left), get_width(right), get_width(center),
    api.nvim_win_get_width(winid)

  if (w_win - (w_left + w_right)) >= w_center + 4 then
    local gap = math.max(1, math.floor((w_win - w_center) / 2) - w_left)
    return table.concat({ left, string.rep(" ", gap), center, "%=", right })
  end
  return table.concat({ left, center, right }, "%=")
end

local function invalidate_and_refresh(buf, keys)
  for _, winid in ipairs(fn.win_findbuf(buf)) do
    if win_data[winid] then
      get_win_cache(winid):invalidate(keys)
    end
    refresh_win(winid)
  end
end

local all_keys = { "file_data", "file_status", "directory", "git_branch", "diagnostics", "lsp_clients" }
local group = api.nvim_create_augroup("CustomStatusline", { clear = true })

autocmd({ "BufWinEnter", "BufWritePost" }, {
  group = group,
  callback = function(ev) invalidate_and_refresh(ev.buf, all_keys) end,
})

autocmd("BufModifiedSet", {
  group = group,
  callback = function(ev) invalidate_and_refresh(ev.buf, "file_status") end,
})

autocmd("DirChanged", {
  group = group,
  callback = function(ev) invalidate_and_refresh(ev.buf, { "directory", "git_branch" }) end,
})

autocmd("DiagnosticChanged", {
  group = group,
  callback = function(ev) invalidate_and_refresh(ev.buf, "diagnostics") end,
})

autocmd({ "LspAttach", "LspDetach" }, {
  group = group,
  callback = function(ev) invalidate_and_refresh(ev.buf, "lsp_clients") end,
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
