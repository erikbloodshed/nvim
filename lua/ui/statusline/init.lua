local api = vim.api
local core = require("ui.statusline.core")

local loaded_cmp = false
local function load_cmp()
  if loaded_cmp then return end
  loaded_cmp = true

  local cmp_directory = "ui.statusline.components"
  local config = require("ui.statusline.config")

  local cmp_set = {}
  for _, section in pairs(config.layout) do
    for _, name in ipairs(section) do
      cmp_set[name] = true
    end
  end

  cmp_set["simple_title"] = true

  for name, _ in pairs(cmp_set) do
    local ok, spec = pcall(require, cmp_directory .. "." .. name)
    if ok and spec.render then
      core.register_cmp(name, spec.render, { cache_keys = spec.cache_keys })
    end
  end

  require("ui.statusline.autocmds")
end

local function build_section(section_cmp, ctx, apply_hl, sep)
  local parts = {}
  for _, name in ipairs(section_cmp) do
    table.insert(parts, core.render_cmp(name, ctx, apply_hl))
  end
  return core.build(parts, sep)
end

local M = {}

M.status = function(winid)
  if not loaded_cmp then load_cmp() end
  local ctx = core.create_ctx(winid)
  local excluded = ctx.config.excluded
  local layout = ctx.config.layout
  local separator = ctx.config.separator
  if excluded.buftype[ctx.buftype] or excluded.filetype[ctx.filetype] then
    return "%=" .. core.render_cmp("simple_title", ctx, true) .. "%="
  end
  local apply_hl = winid == api.nvim_get_current_win()
  local sep = core.hl_rule(separator, "StatusLineSeparator", apply_hl)
  local left = build_section(layout.left, ctx, apply_hl, sep)
  local right = build_section(layout.right, ctx, apply_hl, sep)
  local center = build_section(layout.center, ctx, apply_hl, " ")
  local w_left = core.get_width(left)
  local w_right = core.get_width(right)
  local w_center = core.get_width(center)
  local w_win = api.nvim_win_get_width(winid)
  if (w_win - (w_left + w_right)) >= w_center + 4 then
    local gap = math.max(1, math.floor((w_win - w_center) / 2) - w_left)
    return table.concat({ left, string.rep(" ", gap), center, "%=", right })
  end
  return table.concat({ left, center, right }, "%=")
end

vim.schedule(function()
  for _, winid in ipairs(api.nvim_list_wins()) do
    core.refresh_win(winid)
  end
end)

return M
