local api = vim.api
local core = require("ui.statusline.core")
local config = require("ui.statusline.config")
local icons = require "ui.icons"

local function create_ctx(winid)
  local bufnr = api.nvim_win_get_buf(winid)
  return {
    bufnr = bufnr,
    winid = winid,
    buftype = vim.bo[bufnr].buftype,
    filetype = vim.bo[bufnr].filetype,
    mode_info = config.modes_tbl[api.nvim_get_mode().mode],
    modified = vim.bo[bufnr].modified,
    readonly = vim.bo[bufnr].readonly,
    config = config,
    icons = icons,
    cache = core.get_win_cache(winid),
    hl_rule = core.hl_rule,
    refresh_win = core.refresh_win,
    win_data = core.win_data[winid],
  }
end

local loaded_cmp, component_specs = false, {}

local function load_cmp()
  if loaded_cmp then return end
  loaded_cmp = true
  local cmp_directory = "ui.statusline.components"
  for _, section in pairs(config.layout) do
    for _, name in ipairs(section) do
      if not component_specs[name] then
        component_specs[name] = string.format("%s.%s", cmp_directory, name)
        core.register_cmp(name)
      end
    end
  end
  component_specs["simple_title"] = string.format("%s.simple_title", cmp_directory)
  core.register_cmp("simple_title")
  vim.schedule(function() require("ui.statusline.autocmds") end)
end

core.set_cmp_specs(component_specs)

local function build_section(section_cmp, ctx, apply_hl, sep)
  local parts = {}
  for _, name in ipairs(section_cmp) do
    parts[#parts + 1] = core.render_cmp(name, ctx, apply_hl)
  end
  return core.build(parts, sep)
end

local M = {}

function M.status(winid)
  if not loaded_cmp then load_cmp() end
  local ctx = create_ctx(winid)
  local excluded = config.excluded
  local layout = config.layout
  local separator = config.separator
  if excluded.buftype[ctx.buftype] or excluded.filetype[ctx.filetype] then
    return "%=" .. core.render_cmp("simple_title", ctx, true) .. "%="
  end
  local apply_hl = winid == api.nvim_get_current_win()
  local sep = core.hl_rule(separator, "StatusLineSeparator", apply_hl)
  local left = build_section(layout.left, ctx, apply_hl, sep)
  local right = build_section(layout.right, ctx, apply_hl, sep)
  local center = build_section(layout.center, ctx, apply_hl, " ")
  local w_left, w_right, w_center = core.width(left), core.width(right), core.width(center)
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
