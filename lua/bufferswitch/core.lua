local M = {}

local utils = require('bufferswitch.utils')
local tabline = require('bufferswitch.tabline')

local buffer_order = {}
local config = {}

local function add_buffer_to_order(bufnr)
  if utils.should_include_buffer(config, bufnr) then
    local found = false
    for _, existing_bufnr in ipairs(buffer_order) do
      if existing_bufnr == bufnr then
        found = true
        break
      end
    end
    if not found then
      table.insert(buffer_order, bufnr)
    end
  end
end

local function remove_buffer_from_order(bufnr)
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
  sanitize_buffer_order()

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    add_buffer_to_order(bufnr)
  end

  if vim.o.showtabline == 2 then
    tabline.debounced_update_tabline(buffer_order)
  end
end

function M.next_buffer()
  if config.disable_in_special and utils.is_special_buffer(config) then
    if config.passthrough_keys_in_special then
      local key = vim.api.nvim_replace_termcodes(config.orig_next_key or "<C-n>", true, true, true)
      vim.api.nvim_feedkeys(key, 'n', false)
    end
    return
  end

  local current_buf = vim.api.nvim_get_current_buf()

  if #buffer_order > 1 then
    if not utils.safe_command("silent! bnext") then
      -- If that fails, try to find next buffer manually
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

      if not next_buf and #buffer_order > 0 then
        next_buf = buffer_order[1]
      end

      if next_buf and next_buf ~= current_buf then
        vim.api.nvim_set_current_buf(next_buf)
      end
    end
  else
    vim.notify("No other buffers to navigate to", vim.log.levels.INFO)
  end

  tabline.manage_tabline(config, buffer_order)
end

function M.prev_buffer()
  -- Don't navigate if we're in a special buffer
  if config.disable_in_special and utils.is_special_buffer(config) then
    if config.passthrough_keys_in_special then
      local key = vim.api.nvim_replace_termcodes(config.orig_prev_key or "<C-p>", true, true, true)
      vim.api.nvim_feedkeys(key, 'n', false)
    end
    return
  end

  local current_buf = vim.api.nvim_get_current_buf()

  if #buffer_order > 1 then
    if not utils.safe_command("silent! bprevious") then
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
          prev_buf = buffer_order[#buffer_order]
        end
      end

      if prev_buf and prev_buf ~= current_buf then
        vim.api.nvim_set_current_buf(prev_buf)
      end
    end
  else
    vim.notify("No other buffers to navigate to", vim.log.levels.INFO)
  end

  tabline.manage_tabline(config, buffer_order)
end

function M.debug_buffers()
  print("Current buffer order:")
  for i, bufnr in ipairs(buffer_order) do
    local name = vim.fn.bufname(bufnr)
    if name == "" then name = "[No Name]" end
    print(string.format("%d: %s (bufnr=%d)", i, name, bufnr))
  end
end

function M.initialize(user_config)
  config = user_config

  if config.show_tabline then
    vim.o.showtabline = 0
  end

  local ag = vim.api.nvim_create_augroup('BufferSwitcher', { clear = true })

  buffer_order = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    add_buffer_to_order(bufnr)
  end

  vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    group = ag,
    callback = function()
      local current_buf = vim.api.nvim_get_current_buf()

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

  vim.api.nvim_create_autocmd({ 'BufAdd' }, {
    group = ag,
    callback = function(ev)
      add_buffer_to_order(ev.buf)
      if config.show_tabline and vim.o.showtabline == 2 then
        tabline.debounced_update_tabline(buffer_order)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = ag,
    callback = function(ev)
      remove_buffer_from_order(ev.buf)
      if config.show_tabline and vim.o.showtabline == 2 then
        tabline.debounced_update_tabline(buffer_order)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'QuickFixCmdPost', 'QuickFixCmdPre' }, {
    group = ag,
    callback = function()
      vim.schedule(M.refresh_buffer_list)
    end,
  })

  vim.api.nvim_create_autocmd({ 'WinClosed' }, {
    group = ag,
    callback = function()
      vim.schedule(M.refresh_buffer_list)
    end,
  })

  if config.periodic_cleanup then
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      group = ag,
      callback = function()
        sanitize_buffer_order()
      end,
    })
  end

  M.get_buffer_order = function()
    return buffer_order
  end
end

return M
