local api, keymap = vim.api, vim.keymap.set

local win_close = function()
  vim.cmd.stopinsert()
  vim.schedule(function() api.nvim_win_close(0, true) end)
end

local function get_cword()
  local cword = vim.fn.expand("<cword>")
  return cword ~= "" and cword or nil
end

---@diagnostic disable: duplicate-set-field
vim.ui.input = function(opts, on_confirm)
  opts = opts or {}
  local prompt = opts.prompt or "Input: "
  if prompt == "New Name: " then prompt = " New Name " end
  local default = opts.default or ""
  if prompt == " New Name " and default == "" then
    local cword = get_cword()
    if cword then default = cword end
  end
  local default_width = #default + 10
  local prompt_width = #prompt + 10
  local input_width = math.max(default_width, prompt_width)
  local win_config = {
    relative = "cursor",
    row = 1,
    col = 0,
    focusable = false,
    style = "minimal",
    border = "rounded",
    width = input_width,
    height = 1,
    title = prompt,
    title_pos = "center",
    noautocmd = true,
  }
  if prompt ~= " New Name " then
    win_config.relative = "win"
    win_config.row = math.max(api.nvim_win_get_height(0) / 2 - 1, 0)
    win_config.col = math.max(api.nvim_win_get_width(0) / 2 - input_width / 2, 0)
  end
  local bufnr = api.nvim_create_buf(false, true)
  api.nvim_open_win(bufnr, true, win_config)
  api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, { default })
  vim.cmd.startinsert()
  api.nvim_win_set_cursor(0, { 1, #default + 1 })
  on_confirm = on_confirm or function() end
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
