local api = vim.api
local core = require("ui.statusline.core")
local config = require("ui.statusline.config")
local icons = require("ui.icons")

local M = {}

local loaded_cmp, component_specs = false, {}

local function load_cmp()
  if loaded_cmp then return end
  loaded_cmp = true
  local events_map = {}
  local components_to_load = {}
  for _, section in pairs(config.layout) do
    vim.list_extend(components_to_load, section)
  end
  table.insert(components_to_load, "simple_title")
  for _, name in ipairs(components_to_load) do
    if not component_specs[name] then
      local path = string.format("ui.statusline.components.%s", name)
      component_specs[name] = path
      core.register_cmp(name)
      local ok, spec = pcall(require, path)
      if ok and spec and spec.events and spec.cache_keys then
        for _, event in ipairs(spec.events) do
          events_map[event] = events_map[event] or {}
          for _, key in ipairs(spec.cache_keys) do
            events_map[event][key] = true
          end
        end
      end
    end
  end
  core.set_cmp_specs(component_specs)
  vim.schedule(function()
    require("ui.statusline.autocmds").setup(events_map)
  end)
end

local function build_section(section_cmp, ctx, apply_hl, sep)
  local parts = {}
  for _, name in ipairs(section_cmp) do
    parts[#parts + 1] = core.render_cmp(name, ctx, apply_hl)
  end
  return core.build(parts, sep)
end

local function create_ctx(winid, bufnr)
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

function M.status(winid)
  if not loaded_cmp then load_cmp() end
  local ctx = create_ctx(winid, api.nvim_win_get_buf(winid))
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
