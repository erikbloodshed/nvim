local api = vim.api

local M = {}

M.set_win_options = function(win, options)
  for opt, val in pairs(options) do
    api.nvim_set_option_value(opt, val, { win = win })
  end
end

M.set_buf_options = function(buf, options)
  for opt, val in pairs(options) do
    api.nvim_set_option_value(opt, val, { buf = buf })
  end
end

-- Simple UI dimensions - no caching needed
M.get_ui_dimensions = function()
  local ui = api.nvim_list_uis()[1]
  if ui then
    return ui.width, ui.height
  end
  return 80, 24 -- Fallback
end

M.create_title = function(name)
  return ' ' .. name:gsub("^%l", string.upper) .. ' '
end

return M
