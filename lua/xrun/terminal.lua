-- Simple toggle terminal for Neovim
local M = {}

local buf = nil
local win = nil

function M.toggle()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, false)
    win = nil
    return
  end

  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
  end

  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * 0.8)
  local height = math.floor(ui.height * 0.8)
  local col = math.floor((ui.width - width) / 2)
  local row = math.floor((ui.height - height) / 2)

  win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
    title = ' Terminal ',
    title_pos = 'center',
  })

  -- Start terminal if buffer is empty
  if vim.bo[buf].buftype ~= 'terminal' then
    vim.cmd('terminal')
    buf = vim.api.nvim_get_current_buf()
  end

  vim.cmd('startinsert')
end

return M

