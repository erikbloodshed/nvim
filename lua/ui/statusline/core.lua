local api, fn = vim.api, vim.fn

local M = {}

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

M.CacheMan = CacheMan

local win_data = setmetatable({}, { __mode = "k" })
M.win_data = win_data

function M.get_win_cache(winid)
  local data = win_data[winid]
  if not data then
    data = { cache = CacheMan.new(), git = {}, icons = {} }
    win_data[winid] = data
  end
  return data.cache
end

local components = {}

M.register_cmp = function(name, render_fn, opts)
  opts = opts or {}
  components[name] = { render = render_fn, cache_keys = opts.cache_keys or {} }
end

function M.render_cmp(name, ctx, apply_hl)
  local ok, result = pcall(components[name].render, ctx, apply_hl)
  return ok and result or ""
end

function M.create_ctx(winid)
  local config = require("ui.statusline.config")
  local buf = api.nvim_win_get_buf(winid)
  local bo = vim.bo[buf]
  return {
    winid = winid,
    bufnr = buf,
    cache = M.get_win_cache(winid),
    windat = win_data[winid],
    filetype = bo.filetype,
    buftype = bo.buftype,
    readonly = bo.readonly,
    modified = bo.modified,
    mode_info = config.modes_tbl[api.nvim_get_mode().mode],
  }
end

local status_expr = "%%!v:lua.require'ui.statusline'.status(%d)"

function M.refresh_win(winid)
  if api.nvim_win_is_valid(winid) then
    vim.wo[winid].statusline = string.format(status_expr, winid)
    return
  end
  win_data[winid] = nil
end

local format_expr = "%%#%s#%s%%*"
function M.hl_rule(content, hl, apply_hl)
  if not apply_hl or not hl or not content then return content or "" end
  return string.format(format_expr, hl, content)
end

local w_cache = setmetatable({}, { __mode = "k" })
function M.get_width(s)
  if not s or s == "" then return 0 end
  if not w_cache[s] then
    w_cache[s] = fn.strdisplaywidth(s:gsub("%%#[^#]-#", ""):gsub("%%[*=<]", ""))
  end
  return w_cache[s]
end

function M.build(parts, sep)
  local tbl = {}
  for _, part in ipairs(parts) do
    if part and part ~= "" then tbl[#tbl + 1] = part end
  end
  return table.concat(tbl, sep)
end

return M
