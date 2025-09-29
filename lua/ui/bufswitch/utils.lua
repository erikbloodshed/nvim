local api, fn = vim.api, vim.fn
local config = require("ui.bufswitch.config")

local M = {}

function M.remove_item(tbl, val)
  for i, x in ipairs(tbl) do
    if x == val then
      table.remove(tbl, i)
      return true
    end
  end
  return false
end

function M.is_special(buf)
  buf = buf or api.nvim_get_current_buf()
  if
    vim.tbl_contains(config.special_buftypes, vim.bo[buf].buftype)
    or vim.tbl_contains(config.special_filetypes, vim.bo[buf].filetype)
  then
    return true
  end
  for _, pat in ipairs(config.special_bufname_patterns) do
    if fn.bufname(buf):match(pat) then
      return true
    end
  end
  return fn.win_gettype() ~= ""
end

function M.should_include_buffer(buf)
  return api.nvim_buf_is_valid(buf) and fn.buflisted(buf) == 1 and not M.is_special(buf)
end

return M
