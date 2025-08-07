local api = vim.api

local M = {}

-- Batch set options to reduce API calls
function M.set_win_options(win, options)
  -- Separate window-specific options that can be batched
  local win_config = {}
  local individual_opts = {}

  for opt, val in pairs(options) do
    if opt == 'number' or opt == 'relativenumber' or opt == 'signcolumn' or opt == 'wrap' then
      individual_opts[opt] = val
    else
      win_config[opt] = val
    end
  end

  -- Batch window config options
  if next(win_config) then
    pcall(api.nvim_win_set_config, win, win_config)
  end

  -- Set remaining options individually (only if needed)
  for opt, val in pairs(individual_opts) do
    api.nvim_set_option_value(opt, val, { win = win })
  end
end

function M.set_buf_options(buf, options)
  for opt, val in pairs(options) do
    api.nvim_set_option_value(opt, val, { buf = buf })
  end
end

local ui_cache = { width = nil, height = nil, timestamp = 0 }
local UI_CACHE_TTL = 1000 -- 1 second in milliseconds

api.nvim_create_autocmd('VimResized', {
  callback = function()
    ui_cache.width = nil
    ui_cache.height = nil
    ui_cache.timestamp = 0
  end,
  desc = 'Invalidate UI dimensions cache'
})

function M.get_ui_dimensions()
  local now = vim.uv.hrtime() / 1000000   -- Convert to milliseconds

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

  return 80, 24   -- Fallback dimensions
end

-- Create title with proper casing
function M.create_title(name)
  return ' ' .. name:gsub("^%l", string.upper) .. ' '
end

return M
