local api, fn = vim.api, vim.fn
local autocmd = api.nvim_create_autocmd

local config = {
  seps = " ",
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

local components = {}
local component_modules = {}

local CacheManager = require('ui.statusline.cache')
local win_data = setmetatable({}, { __mode = "k" })

local function get_win_cache(winid)
  local d = win_data[winid]
  if not d then
    d = { cache = CacheManager.new(), git = {}, icons = {} }
    win_data[winid] = d
  end
  return d.cache
end

local function register_component(name, module_or_fn, opts)
  if type(module_or_fn) == "table" then
    -- It's a module
    component_modules[name] = module_or_fn
    components[name] = {
      render = module_or_fn.render,
      cache_keys = module_or_fn.cache_keys or {},
      enabled = module_or_fn.enabled ~= false,
      priority = module_or_fn.priority or 0,
    }
  else
    opts = opts or {}
    components[name] = {
      render = module_or_fn,
      cache_keys = opts.cache_keys or {},
      enabled = opts.enabled ~= false,
      priority = opts.priority or 0,
    }
  end
end

-- Context creation
local function create_context(winid, bufnr)
  return {
    winid = winid,
    bufnr = bufnr,
    cache = get_win_cache(winid),
    wdata = win_data[winid],
    bo = vim.bo[bufnr],
    wo = vim.wo[winid],
    config = config,
  }
end

-- Utility functions
local function conditional_hl(content, hl, apply_hl)
  if not apply_hl or not hl or not content or content == "" then return content or "" end
  return string.format("%%#%s#%s%%*", hl, content)
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

-- Component rendering
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

-- Width calculation
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

-- Section rendering
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

local function status(winid)
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

local function setup_autocmds()
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
end

local default_components = {
  'mode', 'directory', 'git_branch', 'file_display',
  'file_status', 'diagnostics', 'lsp_status',
  'position', 'percentage', 'simple_title'
}

for _, name in ipairs(default_components) do
  if not component_modules[name] then
    local ok, module = pcall(require, 'ui.statusline.components.' .. name)
    if ok then
      register_component(name, module)
    end
  end
end

setup_autocmds()

local M = {
  status = status,
  register_component = register_component,
  conditional_hl = conditional_hl,
  refresh_win = refresh_win,
}

return M

