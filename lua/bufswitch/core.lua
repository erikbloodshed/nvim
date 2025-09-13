local M = {}

local utils = require('bufswitch.utils')
local tabline = require('bufswitch.tabline')

-- Module state
local buffer_order = {}
local config = {}
local is_initialized = false

-- Helper function to handle special buffer navigation
local function handle_special_buffer_navigation(is_next)
  if not (config.disable_in_special and utils.is_special_buffer(config)) then
    return false -- Continue with normal navigation
  end

  if config.passthrough_keys_in_special then
    local key_config = is_next and (config.orig_next_key or "<C-n>") or (config.orig_prev_key or "<C-p>")
    local key_success, key = pcall(vim.api.nvim_replace_termcodes, key_config, true, true, true)

    if key_success then
      pcall(vim.api.nvim_feedkeys, key, 'n', false)
    else
      vim.notify("Failed to process passthrough key", vim.log.levels.WARN)
    end
  end

  return true -- Special buffer handled, skip normal navigation
end

-- Safe buffer switching with fallback logic
local function switch_to_buffer(target_bufnr, fallback_fn)
  if not target_bufnr or target_bufnr == vim.api.nvim_get_current_buf() then
    if fallback_fn then
      return fallback_fn()
    end
    return false
  end

  if not vim.api.nvim_buf_is_valid(target_bufnr) then
    if fallback_fn then
      return fallback_fn()
    end
    return false
  end

  local success, err = pcall(vim.api.nvim_set_current_buf, target_bufnr)
  if not success then
    vim.notify("Failed to switch buffer: " .. tostring(err), vim.log.levels.WARN)
    if fallback_fn then
      return fallback_fn()
    end
    return false
  end

  return true
end

local function add_buffer_to_order(bufnr)
  if not bufnr or not utils.should_include_buffer(config, bufnr) then
    return
  end

  -- Check if buffer already exists in order
  for _, existing_bufnr in ipairs(buffer_order) do
    if existing_bufnr == bufnr then
      return -- Already in order
    end
  end

  table.insert(buffer_order, bufnr)
end

local function remove_buffer_from_order(bufnr)
  if not bufnr then
    return
  end

  for i, existing_bufnr in ipairs(buffer_order) do
    if existing_bufnr == bufnr then
      table.remove(buffer_order, i)
      break
    end
  end
end

local function sanitize_buffer_order()
  local i = 1
  while i <= #buffer_order do
    local bufnr = buffer_order[i]
    if not utils.should_include_buffer(config, bufnr) then
      table.remove(buffer_order, i)
    else
      i = i + 1
    end
  end
end

function M.refresh_buffer_list()
  if not is_initialized then
    vim.notify("BufferSwitch not initialized", vim.log.levels.WARN)
    return
  end

  sanitize_buffer_order()

  -- Add any new buffers to the order
  local buf_list_success, buf_list = pcall(vim.api.nvim_list_bufs)
  if buf_list_success then
    for _, bufnr in ipairs(buf_list) do
      add_buffer_to_order(bufnr)
    end
  else
    vim.notify("Failed to get buffer list", vim.log.levels.ERROR)
    return
  end

  -- Update tabline if configured to show
  if config.show_tabline and vim.o.showtabline == 2 then
    tabline.debounced_update_tabline(buffer_order)
  end

  -- Invalidate tabline cache when buffer list changes
  tabline.invalidate_cache()
end

function M.next_buffer()
  if not is_initialized then
    vim.notify("BufferSwitch not initialized", vim.log.levels.ERROR)
    return
  end

  -- Handle special buffer navigation
  if handle_special_buffer_navigation(true) then
    return
  end

  local current_buf_success, current_buf = pcall(vim.api.nvim_get_current_buf)
  if not current_buf_success then
    vim.notify("Failed to get current buffer", vim.log.levels.ERROR)
    return
  end

  if #buffer_order <= 1 then
    vim.notify("No other buffers to navigate to", vim.log.levels.INFO)
    tabline.manage_tabline(config, buffer_order)
    return
  end

  -- Try built-in bnext first
  if utils.safe_command("silent! bnext") then
    tabline.manage_tabline(config, buffer_order)
    return
  end

  -- Fallback: find next buffer manually
  local found_current = false
  local next_buf = nil

  for _, bufnr in ipairs(buffer_order) do
    if found_current then
      next_buf = bufnr
      break
    end
    if bufnr == current_buf then
      found_current = true
    end
  end

  -- Wrap around to first buffer if we reached the end
  if not next_buf and #buffer_order > 0 then
    next_buf = buffer_order[1]
  end

  local switch_success = switch_to_buffer(next_buf, function()
    vim.notify("Failed to navigate to next buffer", vim.log.levels.WARN)
    return false
  end)

  if switch_success then
    tabline.manage_tabline(config, buffer_order)
  end
end

function M.prev_buffer()
  if not is_initialized then
    vim.notify("BufferSwitch not initialized", vim.log.levels.ERROR)
    return
  end

  -- Handle special buffer navigation
  if handle_special_buffer_navigation(false) then
    return
  end

  local current_buf_success, current_buf = pcall(vim.api.nvim_get_current_buf)
  if not current_buf_success then
    vim.notify("Failed to get current buffer", vim.log.levels.ERROR)
    return
  end

  if #buffer_order <= 1 then
    vim.notify("No other buffers to navigate to", vim.log.levels.INFO)
    tabline.manage_tabline(config, buffer_order)
    return
  end

  -- Try built-in bprevious first
  if utils.safe_command("silent! bprevious") then
    tabline.manage_tabline(config, buffer_order)
    return
  end

  -- Fallback: find previous buffer manually
  local prev_buf = nil
  local found_index = nil

  for i, bufnr in ipairs(buffer_order) do
    if bufnr == current_buf then
      found_index = i
      break
    end
  end

  if found_index then
    if found_index > 1 then
      prev_buf = buffer_order[found_index - 1]
    else
      -- Wrap around to last buffer
      prev_buf = buffer_order[#buffer_order]
    end
  end

  local switch_success = switch_to_buffer(prev_buf, function()
    vim.notify("Failed to navigate to previous buffer", vim.log.levels.WARN)
    return false
  end)

  if switch_success then
    tabline.manage_tabline(config, buffer_order)
  end
end

function M.debug_buffers()
  if not is_initialized then
    print("BufferSwitch not initialized")
    return
  end

  print("Current buffer order:")
  for i, bufnr in ipairs(buffer_order) do
    local name_success, name = pcall(vim.fn.bufname, bufnr)
    if not name_success then
      name = "[Error getting name]"
    elseif name == "" then
      name = "[No Name]"
    end

    local valid = vim.api.nvim_buf_is_valid(bufnr) and "valid" or "invalid"
    print(string.format("%d: %s (bufnr=%d, %s)", i, name, bufnr, valid))
  end

  print(string.format("Total buffers in order: %d", #buffer_order))
  print(string.format("Show tabline: %s", config.show_tabline and "true" or "false"))
  print(string.format("Current showtabline: %d", vim.o.showtabline))
end

function M.initialize(user_config)
  if not user_config then
    vim.notify("initialize: user_config is required", vim.log.levels.ERROR)
    return false
  end

  config = user_config
  is_initialized = false -- Reset state during initialization

  -- Configure tabline behavior
  if config.show_tabline then
    vim.o.showtabline = 0 -- Start hidden, will be shown when needed
  end

  -- Create autocommand group
  local group_success, ag = pcall(vim.api.nvim_create_augroup, 'BufferSwitcher', { clear = true })
  if not group_success then
    vim.notify("Failed to create autocommand group", vim.log.levels.ERROR)
    return false
  end

  -- Initialize buffer order
  buffer_order = {}
  local buf_list_success, buf_list = pcall(vim.api.nvim_list_bufs)
  if buf_list_success then
    for _, bufnr in ipairs(buf_list) do
      add_buffer_to_order(bufnr)
    end
  else
    vim.notify("Failed to initialize buffer list", vim.log.levels.WARN)
  end

  -- Set up autocommands with error handling
  local autocmd_success = pcall(function()
    -- Buffer enter event
    vim.api.nvim_create_autocmd({ 'BufEnter' }, {
      group = ag,
      callback = function()
        local current_buf_success, current_buf = pcall(vim.api.nvim_get_current_buf)
        if not current_buf_success then
          return
        end

        -- Hide tabline if in special buffer
        if config.hide_in_special and utils.is_special_buffer(config, current_buf) then
          if vim.o.showtabline == 2 then
            vim.o.showtabline = 0
          end
          return
        end

        add_buffer_to_order(current_buf)

        if config.show_tabline and vim.o.showtabline == 2 then
          tabline.debounced_update_tabline(buffer_order)
        end
      end,
    })

    -- Buffer add event
    vim.api.nvim_create_autocmd({ 'BufAdd' }, {
      group = ag,
      callback = function(ev)
        if ev.buf then
          add_buffer_to_order(ev.buf)
          tabline.invalidate_cache()

          if config.show_tabline and vim.o.showtabline == 2 then
            tabline.debounced_update_tabline(buffer_order)
          end
        end
      end,
    })

    -- Buffer delete/wipeout events
    vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
      group = ag,
      callback = function(ev)
        if ev.buf then
          remove_buffer_from_order(ev.buf)
          tabline.invalidate_cache()

          if config.show_tabline and vim.o.showtabline == 2 then
            tabline.debounced_update_tabline(buffer_order)
          end
        end
      end,
    })

    -- QuickFix events
    vim.api.nvim_create_autocmd({ 'QuickFixCmdPost', 'QuickFixCmdPre' }, {
      group = ag,
      callback = function()
        vim.schedule(M.refresh_buffer_list)
      end,
    })

    -- Window closed event
    vim.api.nvim_create_autocmd({ 'WinClosed' }, {
      group = ag,
      callback = function()
        vim.schedule(M.refresh_buffer_list)
      end,
    })

    -- Periodic cleanup if enabled
    if config.periodic_cleanup then
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        group = ag,
        callback = function()
          sanitize_buffer_order()
        end,
      })
    end
  end)

  if not autocmd_success then
    vim.notify("Failed to set up autocommands", vim.log.levels.ERROR)
    return false
  end

  is_initialized = true

  -- Expose buffer order getter
  M.get_buffer_order = function()
    return vim.deepcopy(buffer_order) -- Return copy to prevent external modification
  end

  M.is_initialized = function()
    return is_initialized
  end

  return true
end

-- Cleanup function for when plugin is disabled/reloaded
function M.cleanup()
  -- Clean up timers
  local hide_timer = utils.get_hide_timer()
  if utils.cleanup_timer(hide_timer) then
    utils.set_hide_timer(nil)
  end

  -- Clear autocommands
  pcall(vim.api.nvim_del_augroup_by_name, 'BufferSwitcher')

  -- Reset state
  buffer_order = {}
  config = {}
  is_initialized = false

  -- Reset tabline if it was modified
  if vim.o.showtabline == 2 then
    vim.o.showtabline = 1 -- Reset to default
  end
end

return M
