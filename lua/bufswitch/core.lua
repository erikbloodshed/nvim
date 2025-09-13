local M = {}

local utils = require('bufswitch.utils')
local tabline = require('bufswitch.tabline')

local config = {}

-- Simplified: Compute buffer order on-demand (stable by getbufinfo order, filtered)
local function get_buffer_order()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  table.sort(bufs, function(a, b) return a.lnum < b.lnum end) -- Stable sort by internal order
  local order = {}
  for _, buf in ipairs(bufs) do
    if utils.should_include_buffer(config, buf.bufnr) then
      table.insert(order, buf.bufnr)
    end
  end
  return order
end

function M.refresh_buffer_list()
  local buffer_order = get_buffer_order()
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

  local buffer_order = get_buffer_order()
  local current_buf = vim.api.nvim_get_current_buf()

  if #buffer_order > 1 then
    local ok = pcall(vim.api.nvim_cmd, {
      cmd = "bnext",
      mods = { emsg_silent = true } --- @diagnostic disable-line: missing-fields
    })
    if not ok then
      -- Manual fallback
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

  tabline.manage_tabline(config, get_buffer_order())
end

function M.prev_buffer()
  if config.disable_in_special and utils.is_special_buffer(config) then
    if config.passthrough_keys_in_special then
      local key = vim.api.nvim_replace_termcodes(config.orig_prev_key or "<C-p>", true, true, true)
      vim.api.nvim_feedkeys(key, 'n', false)
    end
    return
  end

  local buffer_order = get_buffer_order()
  local current_buf = vim.api.nvim_get_current_buf()

  if #buffer_order > 1 then
    local ok = pcall(vim.api.nvim_cmd, {
      cmd = "bprevious",
      mods = { emsg_silent = true } --- @diagnostic disable-line: missing-fields
    })
    if not ok then
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

  tabline.manage_tabline(config, get_buffer_order())
end

function M.debug_buffers()
  local buffer_order = get_buffer_order()
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

  -- Initial refresh
  M.refresh_buffer_list()

  -- Simplified autocmds: Only BufEnter/BufLeave for refreshes; BufWinLeave for deletes
  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufLeave' }, {
    group = ag,
    callback = function()
      local current_buf = vim.api.nvim_get_current_buf()
      if config.hide_in_special and utils.is_special_buffer(config, current_buf) then
        if vim.o.showtabline == 2 then
          vim.o.showtabline = 0
        end
        return
      end
      if config.show_tabline and vim.o.showtabline == 2 then
        M.refresh_buffer_list()
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout', 'BufWinLeave' }, {
    group = ag,
    callback = function()
      if config.show_tabline and vim.o.showtabline == 2 then
        M.refresh_buffer_list()
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

  M.get_buffer_order = get_buffer_order
end

return M
