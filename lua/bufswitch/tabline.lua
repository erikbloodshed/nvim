local M = {}

local utils = require("bufswitch.utils")

-- Constants for display formatting
local ELLIPSIS = "…"
local MIN_TAB_WIDTH = 5
local INITIAL_MAX_TAB_WIDTH = 15
local PADDING_WIDTH = 2 -- Space on each side of label

-- Cache for formatted names to improve performance
local name_cache = {}
local cache_version = 0

-- Check for devicons availability
local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

-- Invalidate the name cache (call when buffers change significantly)
function M.invalidate_cache()
  cache_version = cache_version + 1
  -- Clear old cache entries periodically to prevent memory leaks
  if cache_version % 100 == 0 then
    name_cache = {}
  end
end

function M.format_buffer_name(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return '[Invalid]'
  end

  -- Check cache first
  local cache_key = bufnr .. "_" .. cache_version
  if name_cache[cache_key] then
    return name_cache[cache_key]
  end

  local name_success, name = pcall(vim.fn.bufname, bufnr)
  if not name_success then
    name = ""
  end

  local display_name = vim.fn.fnamemodify(name, ':t')

  local buf_type_success, buf_type = pcall(function() return vim.bo[bufnr].buftype end)
  if not buf_type_success then
    buf_type = ""
  end

  -- Handle special buffer types
  if buf_type == 'help' then
    display_name = "[Help] " .. (display_name ~= '' and display_name or 'help')
  elseif display_name == '' then
    display_name = '[No Name]'
  end

  -- Add icon if devicons is available
  local icon = ''
  if has_devicons and display_name ~= '[No Name]' and not display_name:match("^%[.*%]") then
    local ext = display_name:match('%.([^%.]+)$') or ''
    local icon_result, _ = pcall(function()
      return devicons.get_icon(display_name, ext, { default = true }) or ''
    end)

    if icon_result then
      icon = _ or ''
    end
  end

  local formatted_name = (icon ~= '' and icon .. ' ' or '') .. display_name

  -- Cache the result
  name_cache[cache_key] = formatted_name
  return formatted_name
end

-- Calculate optimal tab widths given available space
local function calculate_tab_widths(buffer_order, max_width)
  local num_buffers = #buffer_order
  if num_buffers == 0 then
    return {}
  end

  -- Calculate space used by separators
  local separator_space = math.max(0, (num_buffers - 1))
  local available_width = max_width - separator_space

  -- Get desired widths for all tabs
  local tab_info = {}
  local total_desired_width = 0

  for _, bufnr in ipairs(buffer_order) do
    local full_name = M.format_buffer_name(bufnr)
    local desired_width = math.min(vim.fn.strwidth(full_name) + PADDING_WIDTH, INITIAL_MAX_TAB_WIDTH)

    tab_info[bufnr] = {
      full_name = full_name,
      desired_width = desired_width
    }
    total_desired_width = total_desired_width + desired_width
  end

  -- Calculate actual widths based on available space
  local tab_widths = {}

  if total_desired_width <= available_width then
    -- We have enough space for all desired widths
    for bufnr, info in pairs(tab_info) do
      tab_widths[bufnr] = {
        display_name = info.full_name,
        width = info.desired_width
      }
    end
  else
    -- Need to compress tabs
    local target_width = math.floor(available_width / num_buffers)
    target_width = math.max(target_width, MIN_TAB_WIDTH)

    for bufnr, info in pairs(tab_info) do
      local display_name = info.full_name
      local actual_width = math.min(info.desired_width, target_width)

      -- Truncate if necessary
      local content_width = actual_width - PADDING_WIDTH
      if vim.fn.strwidth(display_name) > content_width and content_width > 1 then
        -- Leave room for ellipsis
        local truncate_width = math.max(1, content_width - vim.fn.strwidth(ELLIPSIS))
        display_name = string.sub(display_name, 1, truncate_width) .. ELLIPSIS
      end

      tab_widths[bufnr] = {
        display_name = display_name,
        width = actual_width
      }
    end
  end

  return tab_widths
end

function M.update_tabline_display(buffer_order)
  if not buffer_order or #buffer_order == 0 then
    vim.o.tabline = '%#TabLineFill#%='
    return
  end

  local current_buf_success, current_buf = pcall(vim.api.nvim_get_current_buf)
  if not current_buf_success then
    vim.o.tabline = '%#TabLineFill#%='
    return
  end

  local max_width = vim.o.columns
  if max_width <= 0 then
    max_width = 80 -- fallback width
  end

  local tab_widths = calculate_tab_widths(buffer_order, max_width)
  local parts = {}

  for _, bufnr in ipairs(buffer_order) do
    local tab_info = tab_widths[bufnr]
    if not tab_info then
      goto continue
    end

    local display_name = tab_info.display_name
    local width = tab_info.width

    -- Create padded label
    local content_width = width - PADDING_WIDTH
    local label = string.format(' %-' .. content_width .. 's ', display_name)

    -- Apply highlighting based on whether it's the current buffer
    if bufnr == current_buf then
      table.insert(parts, '%#TabLineSel#' .. label)
    else
      table.insert(parts, '%#TabLine#' .. label)
    end

    ::continue::
  end

  if #parts > 0 then
    vim.o.tabline = table.concat(parts, '%#TabLine#|') .. '%#TabLineFill#%='
  else
    vim.o.tabline = '%#TabLineFill#%='
  end
end

-- Debounced tabline update function
function M.debounced_update_tabline(buffer_order)
  utils.debounce(function()
    local success, err = pcall(M.update_tabline_display, buffer_order)
    if not success then
      vim.notify("Error updating tabline: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

function M.manage_tabline(config, buffer_order)
  if not config then
    vim.notify("manage_tabline: config is nil", vim.log.levels.ERROR)
    return
  end

  buffer_order = buffer_order or {}

  -- Hide tabline if in special buffer
  if config.hide_in_special and utils.is_special_buffer(config) then
    if vim.o.showtabline == 2 then
      vim.o.showtabline = 0
    end
    return
  end

  -- Clean up existing hide timer
  local existing_timer = utils.get_hide_timer()
  if utils.cleanup_timer(existing_timer) then
    utils.set_hide_timer(nil)
  end

  -- Show tabline and update display
  vim.o.showtabline = 2
  local success, err = pcall(M.update_tabline_display, buffer_order)
  if not success then
    vim.notify("Error displaying tabline: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- Set up hide timer if timeout is configured
  if config.hide_timeout and config.hide_timeout > 0 then
    local timer = vim.uv.new_timer()
    if timer then
      utils.set_hide_timer(timer)

      local timer_success, timer_err = pcall(function()
        timer:start(config.hide_timeout, 0, vim.schedule_wrap(function()
          -- Hide tabline after timeout
          if vim.o.showtabline == 2 then
            vim.o.showtabline = 0
          end

          -- Clean up timer
          if utils.cleanup_timer(utils.get_hide_timer()) then
            utils.set_hide_timer(nil)
          end
        end))
      end)

      if not timer_success then
        vim.notify("Failed to start hide timer: " .. tostring(timer_err), vim.log.levels.WARN)
        if utils.cleanup_timer(timer) then
          utils.set_hide_timer(nil)
        end
      end
    else
      vim.notify("Failed to create hide timer", vim.log.levels.WARN)
    end
  end
end

function M.hide_tabline()
  vim.o.showtabline = 0

  -- Clean up any existing hide timer
  local existing_timer = utils.get_hide_timer()
  if utils.cleanup_timer(existing_timer) then
    utils.set_hide_timer(nil)
  end
end

return M
