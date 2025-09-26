local M = {}

local cmp = {}

M.register_cmp = function(name, render_fn, opts)
  opts = opts or {}
  cmp[name] = { render = render_fn, cache_keys = opts.cache_keys or {} }
end

function M.render_cmp(name, ctx, apply_hl)
  local ok, result = pcall(cmp[name].render, ctx, apply_hl)
  return ok and result or ""
end

return M
