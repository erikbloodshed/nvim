local M = {}



-- Helper function to get current mode
local function get_mode()
  local mode_map = {
    n = 'NORMAL',
    i = 'INSERT',
    v = 'VISUAL',
    V = 'V-LINE',
    [''] = 'V-BLOCK',
    c = 'COMMAND',
    R = 'REPLACE',
  }
  return mode_map[vim.fn.mode()] or 'UNKNOWN'
end

-- Helper function to get file name
local function get_filename()
  local filename = vim.fn.expand('%:t')
  return filename ~= '' and filename or '[No Name]'
end

-- Helper function to get file type
local function get_filetype()
  return vim.bo.filetype ~= '' and vim.bo.filetype or 'none'
end

-- Helper function to get line and column info
local function get_line_info()
  return string.format('Ln %d, Col %d', vim.fn.line('.'), vim.fn.col('.'))
end

-- Helper function to check if file is modified
local function get_modified()
  return vim.bo.modified
end

-- Helper function to get filename with appropriate highlight
local function get_filename_with_highlight()
  local filename = vim.fn.expand('%:t')
  local name = filename ~= '' and filename or '[No Name]'

  if get_modified() then
    return '%#StatusLineModified#' .. name .. '%*'
  else
    return '%#StatusLineFile#' .. name .. '%*'
  end
end



-- Define highlight groups with provided colors
vim.api.nvim_set_hl(0, 'StatusLineModified', { fg = '#ff6b6b', bg = 'NONE', bold = true })

-- Main statusline function
function M.statusline()
  local parts = {
    -- Left side - only mode
    '%#StatusLineMode# ',
    get_mode(),
    ' %*',
    '%=', -- Push to center

    -- Center (filename with conditional highlighting)
    get_filename_with_highlight(),

    '%=', -- Push to right

    -- Right side
    '%#StatusLineInfo#',
    get_filetype(),
    ' | ',
    get_line_info(),
    ' %*',
  }
  return table.concat(parts)
end

-- Set the statusline using a direct Lua function call
vim.opt.statusline = '%!v:lua.require("custom_ui.statusline").statusline()'

return M
