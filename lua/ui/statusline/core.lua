local api, fn = vim.api, vim.fn

local CacheMan = {}
CacheMan.__index = CacheMan

function CacheMan.new()
  return setmetatable({ cache = {} }, CacheMan)
end

function CacheMan:get(key, fnc)
  if self.cache[key] ~= nil then return self.cache[key] end
  self.cache[key] = fnc() or nil
  return self.cache[key]
end

function CacheMan:reset(keys)
  if type(keys) == "string" then
    self.cache[keys] = nil
  else
    for _, key in ipairs(keys) do self.cache[key] = nil end
  end
end

local M = {}

M.win_data = {}

function M.get_win_cache(winid)
  local data = M.win_data[winid]
  if not data then
    data = { cache = CacheMan.new(), git = {}, icons = {} }
    M.win_data[winid] = data
  end
  return data.cache
end

local components, component_specs = {}, {}

function M.set_cmp_specs(specs)
  component_specs = specs
end

local function load_component(name)
  local spec = require(component_specs[name])
  components[name] = { render = spec.render, cache_keys = spec.cache_keys or {} }
  return components[name]
end

function M.render_cmp(name, ctx, apply_hl)
  local cmp = components[name] or load_component(name)
  return cmp.render(ctx, apply_hl)
end

local status_expr = "%%!v:lua.require'ui.statusline'.status(%d)"
function M.refresh_win(winid)
  if api.nvim_win_is_valid(winid) then
    vim.wo[winid].statusline = string.format(status_expr, winid)
    return
  end
  M.win_data[winid] = nil
end

local format_expr = "%%#%s#%s%%*"
function M.hl_rule(content, hl, apply_hl)
  if not apply_hl or not hl or not content then return content or "" end
  return string.format(format_expr, hl, content)
end

local w_cache = setmetatable({}, { __mode = "k" })

function M.width(s)
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
