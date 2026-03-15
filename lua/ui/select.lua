local api, opt = vim.api, vim.opt

-- Fetch cursor highlight lazily so we always get the *current* values,
-- not a snapshot taken at module-load time.
local function get_cursor_hl()
  return api.nvim_get_hl(0, { name = "Cursor", link = false })
end

local function hide_cursor()
  local hl = get_cursor_hl()
  api.nvim_set_hl(0, "Cursor", { blend = 100, fg = hl.fg, bg = hl.bg })
  opt.guicursor:append("a:Cursor/lCursor")
end

local function show_cursor()
  local hl = get_cursor_hl()
  api.nvim_set_hl(0, "Cursor", { blend = 0, fg = hl.fg, bg = hl.bg })
  opt.guicursor:remove("a:Cursor/lCursor")
end

local function close_picker(picker)
  show_cursor()

  if picker.augroup then
    api.nvim_del_augroup_by_id(picker.augroup)
    picker.augroup = nil
  end

  if api.nvim_win_is_valid(picker.win) then
    api.nvim_win_close(picker.win, true)
  end
  if api.nvim_buf_is_valid(picker.buf) then
    api.nvim_buf_delete(picker.buf, { force = true })
  end
end

local function move_picker(picker, delta)
  local count = #picker.items
  if count == 0 then return end
  picker.selected = (picker.selected - 1 + delta) % count + 1
  api.nvim_win_set_cursor(picker.win, { picker.selected, 0 })
end

local function pick(opts)
  local lines = {}
  -- Use strdisplaywidth consistently (handles multi-byte / wide chars correctly).
  local max_width = vim.fn.strdisplaywidth(opts.title or "Select")

  for _, item in ipairs(opts.items) do
    local line = item.text or tostring(item)
    table.insert(lines, line)
    max_width = math.max(max_width, vim.fn.strdisplaywidth(line))
  end

  local padding = 4
  local width = math.min(max_width + padding, vim.o.columns - 4)
  local height = math.min(#lines, 10)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "rounded",
    style = "minimal",
    title = opts.title or "Select",
    title_pos = "center",
  })

  api.nvim_set_option_value("cursorline", true, { win = win })

  local picker = {
    buf = buf,
    win = win,
    items = opts.items,
    selected = 1,
    actions = opts.actions or {},
    on_close = opts.on_close or function() end,
  }

  -- Use a unique augroup per picker instance to prevent autocmd leakage.
  local augroup_name = "PickerCursorEvents_" .. buf
  local augroup = api.nvim_create_augroup(augroup_name, { clear = true })
  picker.augroup = augroup

  -- WinEnter / WinLeave are window events; match on the specific window id
  -- via a pattern rather than buffer scoping (which has no effect on these events).
  api.nvim_create_autocmd("WinEnter", {
    group = augroup,
    pattern = "*",
    callback = function()
      if api.nvim_get_current_win() == win then
        hide_cursor()
      end
    end,
  })

  api.nvim_create_autocmd("WinLeave", {
    group = augroup,
    pattern = "*",
    callback = function()
      if api.nvim_get_current_win() == win then
        show_cursor()
      end
    end,
  })

  hide_cursor()
  api.nvim_win_set_cursor(win, { 1, 0 })

  local map_opts = { buffer = buf, nowait = true, noremap = true, silent = true }

  vim.keymap.set("n", "j", function() move_picker(picker, 1) end, map_opts)
  vim.keymap.set("n", "k", function() move_picker(picker, -1) end, map_opts)

  vim.keymap.set("n", "<CR>", function()
    if picker.actions.confirm then
      picker.actions.confirm(picker, picker.items[picker.selected])
    else
      close_picker(picker)
    end
  end, map_opts)

  local function cancel()
    close_picker(picker)
    picker.on_close()
  end

  vim.keymap.set("n", "q", cancel, map_opts)
  vim.keymap.set("n", "<Esc>", cancel, map_opts)

  return picker
end

---Override vim.ui.select with a floating picker.
---@diagnostic disable: duplicate-set-field 
---@param items      any[]
---@param opts       { prompt?: string, format_item?: fun(item: any): string }
---@param on_choice  fun(item: any|nil, idx: integer|nil)
vim.ui.select = function(items, opts, on_choice)
  opts = opts or {}

  local formatted_items = {}
  for idx, item in ipairs(items) do
    local text = opts.format_item and opts.format_item(item) or tostring(item)
    table.insert(formatted_items, { text = text, item = item, idx = idx })
  end

  local completed = false

  -- Wrap on_choice so it fires exactly once regardless of confirm vs cancel path.
  local function finish(item, idx)
    if completed then return end
    completed = true
    vim.schedule(function()
      on_choice(item, idx)
    end)
  end

  pick({
    title = opts.prompt or "Select",
    items = formatted_items,
    actions = {
      confirm = function(picker, picked)
        close_picker(picker)
        finish(picked.item, picked.idx)
      end,
    },
    on_close = function()
      finish(nil, nil)
    end,
  })
end
