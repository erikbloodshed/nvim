local api, keymap = vim.api, vim.keymap.set

local win_close = function()
  vim.cmd.stopinsert()
  vim.defer_fn(function() api.nvim_win_close(0, true) end, 5)
end

local function get_cword()
  local cword = vim.fn.expand("<cword>")
  return cword ~= "" and cword or nil
end

---@diagnostic disable: duplicate-set-field
vim.ui.input = function(opts, on_confirm)
  opts = opts or {}

  local prompt = opts.prompt or "Input: "

  if prompt == "New Name: " then
    prompt = " New Name "
  end

  -- Use word under cursor as default for rename operations
  local default = opts.default or ""
  if prompt == " New Name " and default == "" then
    local cWord = get_cword()
    if cWord then
      default = cWord
    end
  end

  on_confirm = on_confirm or function() end

  local defaultWidth = #default + 10
  local promptWidth = #prompt + 10
  local inputWidth = math.max(defaultWidth, promptWidth)

  local wincfgDefault = {
    relative = "cursor",
    row = 1,
    col = 0,
    focusable = false,
    style = "minimal",
    border = "rounded",
    width = inputWidth,
    height = 1,
    title = prompt,
    title_pos = "center",
    noautocmd = true,
  }

  if prompt ~= " New Name " then
    wincfgDefault.relative = "win"
    wincfgDefault.row = math.max(api.nvim_win_get_height(0) / 2 - 1, 0)
    wincfgDefault.col = math.max(api.nvim_win_get_width(0) / 2 - inputWidth / 2, 0)
  end

  local bufnr = api.nvim_create_buf(false, true)
  api.nvim_open_win(bufnr, true, wincfgDefault)
  api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, { default })

  vim.cmd.startinsert()
  api.nvim_win_set_cursor(0, { 1, #default + 1 })

  keymap({ "n", "i", "v" }, "<cr>", function()
    on_confirm(api.nvim_buf_get_lines(bufnr, 0, 1, false)[1])
    win_close()
  end, { buffer = bufnr })

  keymap("n", "<esc>", function()
    on_confirm(nil)
    win_close()
  end, { buffer = bufnr })

  keymap("n", "q", function()
    on_confirm(nil)
    win_close()
  end, { buffer = bufnr })
end
