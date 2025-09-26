local api, opt = vim.api, vim.opt

local hl = api.nvim_get_hl(0, { name = "Cursor", link = false })

local function hide_cursor()
  api.nvim_set_hl(0, "Cursor", { blend = 100, fg = hl.fg, bg = hl.bg })
  opt.guicursor:append("a:Cursor/lCursor")
end

local function show_cursor()
  api.nvim_set_hl(0, "Cursor", { blend = 0, fg = hl.fg, bg = hl.bg })
  opt.guicursor:remove("a:Cursor/lCursor")
end

local function close_picker(picker)
  show_cursor()

  if picker.augroup then
    api.nvim_del_augroup_by_id(picker.augroup)
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
  local new_idx = (picker.selected - 1 + delta) % count + 1
  picker.selected = new_idx
  api.nvim_win_set_cursor(picker.win, { new_idx, 0 })
end

local function pick(opts)
  local lines = {}
  local max_width = #(opts.title or "Select")
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
    title_pos = "center"
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

  local augroup = api.nvim_create_augroup("PickerCursorEvents", { clear = false })
  picker.augroup = augroup

  api.nvim_create_autocmd("WinEnter", {
    buffer = buf,
    group = augroup,
    callback = hide_cursor,
  })

  api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    group = augroup,
    callback = show_cursor,
  })

  hide_cursor()

  api.nvim_win_set_cursor(win, { 1, 0 })

  vim.keymap.set("n", "j", function() move_picker(picker, 1) end, { buffer = buf, nowait = true })
  vim.keymap.set("n", "k", function() move_picker(picker, -1) end, { buffer = buf, nowait = true })

  vim.keymap.set("n", "<CR>", function()
    if picker.actions.confirm then
      picker.actions.confirm(picker, picker.items[picker.selected])
    else
      close_picker(picker)
    end
  end, { buffer = buf })

  local function cancel()
    close_picker(picker)
    picker.on_close()
  end

  vim.keymap.set("n", "q", cancel, { buffer = buf })
  vim.keymap.set("n", "<Esc>", cancel, { buffer = buf })

  return picker
end

---@diagnostic disable: duplicate-set-field
vim.ui.select = function(items, opts, on_choice)
  opts = opts or {}

  local formatted_items = {}

  for idx, item in ipairs(items) do
    local text = (opts.format_item and opts.format_item(item)) or tostring(item)
    table.insert(formatted_items, {
      text = text,
      item = item,
      idx = idx,
    })
  end

  local completed = false

  pick({
    title = opts.prompt or "Select",
    items = formatted_items,
    actions = {
      confirm = function(picker, picked)
        if completed then return end
        completed = true
        close_picker(picker)
        vim.schedule(function()
          on_choice(picked.item, picked.idx)
        end)
      end,
    },
    on_close = function()
      if completed then return end
      completed = true
      vim.schedule(function()
        on_choice(nil, nil)
      end)
    end,
  })
end
