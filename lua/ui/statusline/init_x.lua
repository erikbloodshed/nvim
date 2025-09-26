local api = vim.api
local core = require("ui.statusline.core")
local config = require("ui.statusline.config")

local loaded_components = false
local function load_components()
  if loaded_components then return end
  loaded_components = true

  local component_dir = "ui.statusline.components"
  local components = {
    "mode", "directory", "git_branch", "file_display",
    "file_status", "simple_title", "diagnostics",
    "lsp_status", "position", "percentage",
  }

  for _, c in ipairs(components) do
    require(component_dir .. "." .. c)
  end

  require("ui.statusline.autocmds")
end

local M = {}

M.status = function(winid)
  if not loaded_components then
    load_components()
  end

  local ctx = core.create_ctx(winid)
  if config.excluded.buftype[ctx.buftype] or config.excluded.filetype[ctx.filetype] then
    return "%=" .. core.render_cmp("simple_title", ctx, true) .. "%="
  end

  local apply_hl = winid == api.nvim_get_current_win()
  local sep = core.hl_rule(config.separator, "StatusLineSeparator", apply_hl)

  local left = core.build({
    core.render_cmp("mode", ctx, apply_hl),
    core.render_cmp("directory", ctx, apply_hl),
    core.render_cmp("git_branch", ctx, apply_hl),
  }, sep)

  local right = core.build({
    core.render_cmp("diagnostics", ctx, apply_hl),
    core.render_cmp("lsp_status", ctx, apply_hl),
    core.render_cmp("position", ctx, apply_hl),
    core.render_cmp("percentage", ctx, apply_hl),
  }, sep)

  local center = core.build({
    core.render_cmp("file_display", ctx, apply_hl),
    core.render_cmp("file_status", ctx, apply_hl),
  }, " ")

  local w_left, w_right, w_center, w_win =
    core.get_width(left), core.get_width(right), core.get_width(center),
    api.nvim_win_get_width(winid)

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
