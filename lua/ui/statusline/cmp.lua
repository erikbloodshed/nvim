local cmp = {}

local function register_cmp(name, render_fn, opts)
  opts = opts or {}
  cmp[name] = { render = render_fn, cache_keys = opts.cache_keys or {} }
end

local function render_cmp(name, ctx, apply_hl)
  local ok, result = pcall(cmp[name].render, ctx, apply_hl)
  return ok and result or ""
end

return {
  cmp = cmp,
  register_cmp = register_cmp,
  render_cmp = render_cmp,
}

