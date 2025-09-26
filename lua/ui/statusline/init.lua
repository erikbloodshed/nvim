local api = vim.api
local core = require("ui.statusline.core")

local components = {
  mode = { priority = 1 },
  simple_title = { priority = 1 },
  file_display = { priority = 2 },
  file_status = { priority = 2 },
  position = { priority = 2 },
  directory = { priority = 3, event = "BufEnter" },
  git_branch = { priority = 3, event = "BufEnter" },
  diagnostics = { priority = 4, event = "DiagnosticChanged" },
  lsp_status = { priority = 4, event = "LspAttach" },
  percentage = { priority = 5 },
}

local loaded = {}
local startup_done = false

local placeholders = {
  git_branch = function() return "" end,
  diagnostics = function() return "" end,
  lsp_status = function() return "" end,
  directory = function(_, apply_hl)
    return core.hl_rule("…", "Comment", apply_hl)
  end,
}

local function load_component(name)
  if loaded[name] then return true end

  local ok, spec = pcall(require, "ui.statusline.components." .. name)
  if ok and spec.render then
    core.register_cmp(name, spec.render, { cache_keys = spec.cache_keys })
    loaded[name] = true
    return true
  end

  -- Use placeholder if available
  if placeholders[name] then
    core.register_cmp(name, placeholders[name], {})
    loaded[name] = true
  end
  return false
end

local function load_by_priority(max_priority, async)
  local to_load = {}
  for name, config in pairs(components) do
    if config.priority <= max_priority and not loaded[name] then
      table.insert(to_load, name)
    end
  end

  if async then
    for i, name in ipairs(to_load) do
      vim.defer_fn(function()
        load_component(name)
        for _, winid in ipairs(api.nvim_list_wins()) do
          core.refresh_win(winid)
        end
      end, i * 10)
    end
  else
    for _, name in ipairs(to_load) do
      load_component(name)
    end
  end
end

local function render_lazy(name, ctx, apply_hl)
  if not load_component(name) and placeholders[name] then
    return placeholders[name](ctx, apply_hl)
  end
  return core.render_cmp(name, ctx, apply_hl)
end

local function setup_events()
  local events = {}
  for name, config in pairs(components) do
    if config.event then
      events[config.event] = events[config.event] or {}
      table.insert(events[config.event], name)
    end
  end

  for event, names in pairs(events) do
    api.nvim_create_autocmd(event, {
      callback = function()
        for _, name in ipairs(names) do
          load_component(name)
        end
        vim.schedule(function()
          for _, winid in ipairs(api.nvim_list_wins()) do
            core.refresh_win(winid)
          end
        end)
      end,
      once = true,
    })
  end
end

local M = {}

M.status = function(winid)
  local ctx = core.create_ctx(winid)
  local excluded = ctx.config.excluded

  if excluded.buftype[ctx.buftype] or excluded.filetype[ctx.filetype] then
    load_component("simple_title")
    return "%=" .. render_lazy("simple_title", ctx, true) .. "%="
  end

  if not startup_done then
    load_by_priority(2, false)
  end

  local apply_hl = winid == api.nvim_get_current_win()
  local sep = core.hl_rule(ctx.config.separator, "StatusLineSeparator", apply_hl)

  local left = core.build({
    render_lazy("mode", ctx, apply_hl),
    render_lazy("directory", ctx, apply_hl),
    render_lazy("git_branch", ctx, apply_hl),
  }, sep)

  local right = core.build({
    render_lazy("diagnostics", ctx, apply_hl),
    render_lazy("lsp_status", ctx, apply_hl),
    render_lazy("position", ctx, apply_hl),
    render_lazy("percentage", ctx, apply_hl),
  }, sep)

  local center = core.build({
    render_lazy("file_display", ctx, apply_hl),
    render_lazy("file_status", ctx, apply_hl),
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

M.debug = function()
  return { loaded = loaded, startup_done = startup_done }
end

vim.schedule(function()
  setup_events()

  vim.defer_fn(function()
    startup_done = true
    load_by_priority(5, true)
  end, 500)

  for _, winid in ipairs(api.nvim_list_wins()) do
    core.refresh_win(winid)
  end

  require("ui.statusline.autocmds")
end)

return M
