local M = {}

local cmps = {}

function M.register_cmp(name, fn)
  cmps[name] = fn
end

function M.render_cmp(name, ctx, apply_hl)
  local fn = cmps[name]
  if not fn then return "" end
  local ok, result = pcall(fn, ctx, apply_hl)
  if not ok then
    vim.schedule(function()
      vim.notify(("statusline component '%s' failed: %s"):format(name, result), vim.log.levels.ERROR)
    end)
    return ""
  end
  return result or ""
end

return M
