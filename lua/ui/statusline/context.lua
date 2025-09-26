local api = vim.api
local core = require("ui.statusline.core")
local config = require("ui.statusline.config")

local function create_ctx(winid)
  local buf = api.nvim_win_get_buf(winid)
  local bo = vim.bo[buf]
  return {
    winid = winid,
    bufnr = buf,
    cache = core.get_win_cache(winid),
    windat = core.win_data[winid],
    filetype = bo.filetype,
    buftype = bo.buftype,
    readonly = bo.readonly,
    modified = bo.modified,
    mode_info = config.modes_tbl[api.nvim_get_mode().mode],
  }
end

return create_ctx

