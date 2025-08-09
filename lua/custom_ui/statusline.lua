local M = {}

-- Mode mapping
local mode_map = {
  n  = 'NORMAL',
  i  = 'INSERT',
  v  = 'VISUAL',
  V  = 'V-LINE',
  [''] = 'V-BLOCK',
  c  = 'COMMAND',
  R  = 'REPLACE',
}

-- Define highlights once
vim.api.nvim_set_hl(0, 'StatusLineModified', { fg = '#ff6b6b', bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'StatusLineFile',     { fg = '#cdd6f4', bg = 'NONE' })
vim.api.nvim_set_hl(0, 'StatusLineMode',     { fg = '#89b4fa', bg = 'NONE', bold = true })
vim.api.nvim_set_hl(0, 'StatusLineInfo',     { fg = '#a6adc8', bg = 'NONE' })

-- Cached components
local cached_mode = ''
local cached_filename = ''
local cached_filetype = ''
local cached_lineinfo = ''

-- Update functions
local function update_mode()
  cached_mode = mode_map[vim.api.nvim_get_mode().mode] or 'UNKNOWN'
end

local function update_filename()
  local name = vim.fn.expand('%:t')
  if name == '' then name = '[No Name]' end
  if vim.bo.modified then
    cached_filename = '%#StatusLineModified#' .. name .. '%*'
  else
    cached_filename = '%#StatusLineFile#' .. name .. '%*'
  end
end

local function update_filetype()
  cached_filetype = (vim.bo.filetype ~= '' and vim.bo.filetype) or 'none'
end

local function update_lineinfo()
  cached_lineinfo = string.format('Ln %d, Col %d', vim.fn.line('.'), vim.fn.col('.'))
end

-- Autocommands to update cached parts
vim.api.nvim_create_autocmd({ 'ModeChanged' }, { callback = update_mode })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'TextChanged', 'TextChangedI' }, {
  callback = function()
    update_filename()
    update_filetype()
  end
})
vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, { callback = update_lineinfo })

-- Initial update
update_mode()
update_filename()
update_filetype()
update_lineinfo()

-- Statusline function just joins cached parts
function M.statusline()
  return table.concat({
    '%#StatusLineMode# ', cached_mode, ' %*',
    '%=',
    cached_filename,
    '%=',
    '%#StatusLineInfo#', cached_filetype, ' | ', cached_lineinfo, ' %*'
  })
end

vim.opt.statusline = '%!v:lua.require("custom_ui.statusline").statusline()'

return M

