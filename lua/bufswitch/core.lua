local M = {}
local utils = require('bufswitch.utils')
local tabline = require('bufswitch.tabline')

local buffer_order = {}
local config = {}
local is_initialized = false

local function handle_special_buffer_navigation(is_next)
  if not config.disable_in_special or not utils.is_special_buffer(config) then
    return false
  end

  if config.passthrough_keys_in_special then
    local key = vim.api.nvim_replace_termcodes(is_next and config.next_key or config.prev_key, true, true, true)
    pcall(vim.api.nvim_feedkeys, key, 'n', false)
  end
  return true
end

local function switch_to_buffer(target_bufnr, fallback_fn)
  if not target_bufnr or target_bufnr == vim.api.nvim_get_current_buf() or not vim.api.nvim_buf_is_valid(target_bufnr) then
    return fallback_fn and fallback_fn() or false
  end

  local success, err = pcall(vim.api.nvim_set_current_buf, target_bufnr)
  if not success then
    vim.notify("Failed to switch buffer: " .. tostring(err), vim.log.levels.WARN)
    return fallback_fn and fallback_fn() or false
  end
  return true
end

local function update_buffer_order(bufnr, action)
  if not bufnr or not utils.should_include_buffer(config, bufnr) then
    return
  end

  if action == "add" then
    if not vim.tbl_contains(buffer_order, bufnr) then
      table.insert(buffer_order, bufnr)
    end
  elseif action == "remove" then
    for i, existing_bufnr in ipairs(buffer_order) do
      if existing_bufnr == bufnr then
        table.remove(buffer_order, i)
        break
      end
    end
  end
end

local function sanitize_buffer_order()
  buffer_order = vim.tbl_filter(function(bufnr)
    return utils.should_include_buffer(config, bufnr)
  end, buffer_order)
end

function M.refresh_buffer_list()
  if not is_initialized then return end

  sanitize_buffer_order()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    update_buffer_order(bufnr, "add")
  end

  if config.show_tabline and vim.o.showtabline == 2 then
    tabline.debounced_update_tabline(buffer_order)
  end
  tabline.invalidate_cache()
end

function M.next_buffer()
  if not is_initialized or handle_special_buffer_navigation(true) then return end

  local current_buf = vim.api.nvim_get_current_buf()
  if #buffer_order <= 1 then
    vim.notify("No other buffers to navigate to", vim.log.levels.INFO)
    tabline.manage_tabline(config, buffer_order)
    return
  end

  if utils.safe_command("silent! bnext") then
    tabline.manage_tabline(config, buffer_order)
    return
  end

  local next_buf
  for i, bufnr in ipairs(buffer_order) do
    if bufnr == current_buf then
      next_buf = buffer_order[i + 1] or buffer_order[1]
      break
    end
  end

  if switch_to_buffer(next_buf) then
    tabline.manage_tabline(config, buffer_order)
  end
end

function M.prev_buffer()
  if not is_initialized or handle_special_buffer_navigation(false) then return end

  local current_buf = vim.api.nvim_get_current_buf()
  if #buffer_order <= 1 then
    vim.notify("No other buffers to navigate to", vim.log.levels.INFO)
    tabline.manage_tabline(config, buffer_order)
    return
  end

  if utils.safe_command("silent! bprevious") then
    tabline.manage_tabline(config, buffer_order)
    return
  end

  local prev_buf
  for i, bufnr in ipairs(buffer_order) do
    if bufnr == current_buf then
      prev_buf = buffer_order[i - 1] or buffer_order[#buffer_order]
      break
    end
  end

  if switch_to_buffer(prev_buf) then
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
    local name = vim.fn.bufname(bufnr) or "[No Name]"
    local valid = vim.api.nvim_buf_is_valid(bufnr) and "valid" or "invalid"
    print(string.format("%d: %s (bufnr=%d, %s)", i, name, bufnr, valid))
  end
  print(string.format("Total buffers: %d, Show tabline: %s, Current showtabline: %d",
    #buffer_order, config.show_tabline, vim.o.showtabline))
end

function M.initialize(user_config)
  config = user_config
  is_initialized = false
  buffer_order = {}

  if config.show_tabline then
    vim.o.showtabline = 0
  end

  local ag = vim.api.nvim_create_augroup('BufferSwitcher', { clear = true })
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    update_buffer_order(bufnr, "add")
  end

  vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    group = ag,
    callback = function()
      local current_buf = vim.api.nvim_get_current_buf()
      if config.hide_in_special and utils.is_special_buffer(config, current_buf) then
        vim.o.showtabline = 0
        return
      end
      update_buffer_order(current_buf, "add")
      if config.show_tabline and vim.o.showtabline == 2 then
        tabline.debounced_update_tabline(buffer_order)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufAdd' }, {
    group = ag,
    callback = function(ev)
      update_buffer_order(ev.buf, "add")
      tabline.invalidate_cache()
      if config.show_tabline and vim.o.showtabline == 2 then
        tabline.debounced_update_tabline(buffer_order)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = ag,
    callback = function(ev)
      update_buffer_order(ev.buf, "remove")
      tabline.invalidate_cache()
      if config.show_tabline and vim.o.showtabline == 2 then
        tabline.debounced_update_tabline(buffer_order)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'QuickFixCmdPost', 'QuickFixCmdPre', 'WinClosed' }, {
    group = ag,
    callback = function()
      vim.schedule(M.refresh_buffer_list)
    end,
  })

  if config.periodic_cleanup then
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      group = ag,
      callback = sanitize_buffer_order,
    })
  end

  is_initialized = true
  M.get_buffer_order = function() return vim.deepcopy(buffer_order) end
  M.is_initialized = function() return is_initialized end
  return true
end

function M.cleanup()
  utils.cleanup_timer(utils.get_hide_timer())
  utils.set_hide_timer(nil)
  pcall(vim.api.nvim_del_augroup_by_name, 'BufferSwitcher')
  buffer_order = {}
  config = {}
  is_initialized = false
  vim.o.showtabline = 1
end

return M
