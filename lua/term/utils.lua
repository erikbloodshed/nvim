local api = vim.api

local M = {}

M.set_win_options = function(win, options)
  local win_config = {}
  local individual_opts = {}

  for opt, val in pairs(options) do
    if opt == 'number' or opt == 'relativenumber' or opt == 'signcolumn' or opt == 'wrap' then
      individual_opts[opt] = val
    else
      win_config[opt] = val
    end
  end

  if next(win_config) then
    pcall(api.nvim_win_set_config, win, win_config)
  end

  for opt, val in pairs(individual_opts) do
    api.nvim_set_option_value(opt, val, { win = win })
  end
end

M.set_buf_options = function(buf, options)
  for opt, val in pairs(options) do
    api.nvim_set_option_value(opt, val, { buf = buf })
  end
end

local ui_cache = { width = nil, height = nil, timestamp = 0 }
local UI_CACHE_TTL = 1000

api.nvim_create_autocmd('VimResized', {
  callback = function()
    ui_cache.width = nil
    ui_cache.height = nil
    ui_cache.timestamp = 0
  end,
  desc = 'Invalidate UI dimensions cache'
})

M.get_ui_dimensions = function()
  local now = vim.uv.hrtime() / 1000000

  if ui_cache.width and ui_cache.height and (now - ui_cache.timestamp) < UI_CACHE_TTL then
    return ui_cache.width, ui_cache.height
  end

  local ui = api.nvim_list_uis()[1]
  if ui then
    ui_cache.width = ui.width
    ui_cache.height = ui.height
    ui_cache.timestamp = now
    return ui.width, ui.height
  end

  return 80, 24
end

M.create_title = function(name)
  return ' ' .. name:gsub("^%l", string.upper) .. ' '
end

return M
