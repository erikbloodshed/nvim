-- statusline/utils.lua
local M = {}

local config = require('statusline.config')
local cache = require('statusline.cache')

--[[
  Debounced Redraw Mechanism
--]]
local last_redraw = 0

function M.debounced_redraw()
  local now = vim.loop.hrtime() / 1e6
  local throttle_config = config.get().throttle

  if now - last_redraw > throttle_config.redraw_ms then
    last_redraw = now
    vim.cmd('redrawstatus')
  end
end

--[[
  Throttled Updates
--]]
local last_cursor_update = 0

function M.throttled_cursor_update()
  local now = vim.loop.hrtime() / 1e6
  local throttle_config = config.get().throttle

  if now - last_cursor_update > throttle_config.cursor_ms then
    last_cursor_update = now
    cache.invalidate_cursor_related()
    vim.schedule(M.refresh_current_statusline)
  end
end

--[[
  Get the display width of a statusline string
--]]
function M.get_display_width(str)
  if not str or str == '' then return 0 end

  -- Remove highlight groups and special characters
  local clean_str = str:gsub('%%#[^#]*#', '') -- Remove highlight groups
    :gsub('%%*', '')                          -- Remove highlight resets
    :gsub('%%=', '')                          -- Remove alignment
    :gsub('%%<', '')                          -- Remove truncation

  return vim.fn.strdisplaywidth(clean_str)
end

--[[
  Check if window should have statusline
--]]
function M.should_have_statusline(win_id)
  local cfg = config.get()

  -- Check floating windows
  if cfg.exclude.floating_windows and
    vim.api.nvim_win_get_config(win_id).relative ~= '' then
    return false
  end

  local buf_id = vim.api.nvim_win_get_buf(win_id)
  local buf_type = vim.api.nvim_get_option_value('buftype', { buf = buf_id })
  local file_type = vim.api.nvim_get_option_value('filetype', { buf = buf_id })

  -- Check excluded buffer types
  for _, skip_type in ipairs(cfg.exclude.buftypes) do
    if buf_type == skip_type then return false end
  end

  -- Check excluded file types
  for _, skip_type in ipairs(cfg.exclude.filetypes) do
    if file_type == skip_type then return false end
  end

  -- Check window size
  if cfg.exclude.small_windows then
    local win_height = vim.api.nvim_win_get_height(win_id)
    local win_width = vim.api.nvim_win_get_width(win_id)
    local min_height = cfg.exclude.small_windows.min_height or 3
    local min_width = cfg.exclude.small_windows.min_width or 20

    if win_height < min_height or win_width < min_width then
      return false
    end
  end

  return true
end

--[[
  Build final statusline with proper centering
--]]
function M.build_statusline(left_section, center_section, right_section, right_components, win_id)
  local cfg = config.get()

  if not cfg.center_filename then
    return left_section .. ' ' .. center_section .. '%=' .. right_section
  end

  -- Calculate section widths for centering
  local left_width = (cache.get_width('mode') or M.get_display_width(left_section))
  if cache.get('git_branch') then
    left_width = left_width + (cache.get_width('git_branch') or 0)
  end

  local right_width = 0
  for _, component in ipairs(right_components) do
    right_width = right_width + (cache.get_width(component) or 0)
  end

  local center_width = cache.get_width('file_info') or M.get_display_width(center_section)
  local win_width = vim.api.nvim_win_get_width(win_id)

  local total_side_width = left_width + right_width
  local available_center = win_width - total_side_width

  -- If not enough space, fallback to left-aligned
  if available_center < center_width + 4 then
    return left_section .. ' ' .. center_section .. '%=' .. right_section
  end

  -- Calculate padding for centering
  local center_start = math.floor((win_width - center_width) / 2)
  local left_padding = math.max(1, center_start - left_width)

  return left_section .. string.rep(' ', left_padding) .. center_section .. '%=' .. right_section
end

--[[
  Refresh current window statusline
--]]
function M.refresh_current_statusline(statusline_fn)
  local win_id = vim.api.nvim_get_current_win()

  if vim.api.nvim_win_is_valid(win_id) and M.should_have_statusline(win_id) then
    local statusline_require = statusline_fn and 'statusline_fn()' or
      '%!v:lua.require("statusline").statusline()'
    vim.wo[win_id].statusline = statusline_require
  else
    vim.wo[win_id].statusline = ''
  end
end

--[[
  Refresh all window statuslines
--]]
function M.refresh_all_statuslines(statusline_fn)
  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_win_call(win_id, function ()
        if M.should_have_statusline(win_id) then
          local statusline_require = statusline_fn and 'statusline_fn()' or
            '%!v:lua.require("statusline").statusline()'
          vim.wo[win_id].statusline = statusline_require
        else
          vim.wo[win_id].statusline = ''
        end
      end)
    end
  end
end

--[[
  Safe function execution with error handling
--]]
function M.safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    vim.notify('Statusline error: ' .. tostring(result), vim.log.levels.ERROR)
    return nil
  end
  return result
end

--[[
  Format bytes to human readable string
--]]
function M.format_bytes(bytes)
  if bytes < 1024 then
    return string.format("%dB", bytes)
  elseif bytes < 1024 * 1024 then
    return string.format("%.1fK", bytes / 1024)
  else
    return string.format("%.1fM", bytes / (1024 * 1024))
  end
end

--[[
  Get buffer info for debugging
--]]
function M.get_buffer_info(buf_id)
  buf_id = buf_id or vim.api.nvim_get_current_buf()

  return {
    id = buf_id,
    name = vim.api.nvim_buf_get_name(buf_id),
    buftype = vim.api.nvim_get_option_value('buftype', { buf = buf_id }),
    filetype = vim.api.nvim_get_option_value('filetype', { buf = buf_id }),
    modified = vim.api.nvim_get_option_value('modified', { buf = buf_id }),
    readonly = vim.api.nvim_get_option_value('readonly', { buf = buf_id }),
  }
end

return M
