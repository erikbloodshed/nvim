local api = vim.api
local core = require("ui.statusline.core")
local config = require("ui.statusline.config")
local icons = require "ui.icons"

local loaded_cmp, component_specs = false, {}

local function create_ctx(winid, bufnr)
  local bo = vim.bo[bufnr]
  local context = {
    hl_rule = core.hl_rule,
    refresh_win = core.refresh_win,
    winid = winid,
    bufnr = bufnr,
    cache = core.get_win_cache(winid),
    win_data = core.win_data[winid],
    filetype = bo.filetype,
    buftype = bo.buftype,
    readonly = bo.readonly,
    modified = bo.modified,
    mode_info = config.modes_tbl[api.nvim_get_mode().mode],
    config = config,
    icons = icons,
  }
  return context
end

local function load_cmp()
  if loaded_cmp then return end
  loaded_cmp = true
  local cmp_directory = "ui.statusline.components"
  for _, section in pairs(config.layout) do
    for _, name in ipairs(section) do
      if not component_specs[name] then
        component_specs[name] = string.format("%s.%s", cmp_directory, name)
        core.register_lazy_cmp(name)
      end
    end
  end
  component_specs["simple_title"] = string.format("%s.simple_title", cmp_directory)
  core.register_lazy_cmp("simple_title")
  vim.schedule(function() require("ui.statusline.autocmds") end)
end

core.set_component_specs(component_specs)

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
  local ctx = create_ctx(winid, api.nvim_win_get_buf(winid))
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
  local w_left, w_right, w_center = core.get_width(left), core.get_width(right), core.get_width(center)
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
