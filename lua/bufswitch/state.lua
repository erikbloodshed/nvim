local M = {
  config = {
    hide_timeout = 800,
    show_tabline = true,
    hide_in_special = true,
    disable_in_special = true,
    periodic_cleanup = true,
    debug = false,
    tabline_display_window = 15,
    wrap_around = false,
    special_buftypes = { "quickfix", "help", "nofile", "prompt", "terminal" },
    special_filetypes = { "qf", "help", "netrw", "neo-tree", "NvimTree" },
    special_bufname_patterns = { "^term://", "^neo%-tree " },
  },

  buffer_order = {},
  tabline_order = {},
  -- NEW: Move index map to state for better encapsulation
  mru_index_map = {},
  tabline_index_map = {},

  cycle = {
    is_active = false,
    index = 0,
  },
}

function M.init_config(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

-- NEW: Helper functions for MRU management
function M.add_buffer_to_mru(bufnr)
  table.insert(M.buffer_order, bufnr)
  M.mru_index_map[bufnr] = #M.buffer_order
end

function M.remove_buffer_from_mru(bufnr)
  local old_index = M.mru_index_map[bufnr]
  if not old_index then return false end

  table.remove(M.buffer_order, old_index)
  M.mru_index_map[bufnr] = nil

  -- Update indices for all buffers after the removed position
  for i = old_index, #M.buffer_order do
    M.mru_index_map[M.buffer_order[i]] = i
  end

  return true
end

function M.move_buffer_to_end_mru(bufnr)
  local old_index = M.mru_index_map[bufnr]
  if old_index then
    table.remove(M.buffer_order, old_index)
    -- Update indices for buffers after the removed position
    for i = old_index, #M.buffer_order do
      M.mru_index_map[M.buffer_order[i]] = i
    end
  end

  table.insert(M.buffer_order, bufnr)
  M.mru_index_map[bufnr] = #M.buffer_order
end

-- NEW: Validation and debugging helpers
function M.validate_mru_consistency()
  if not M.config.debug then return true end

  for bufnr, index in pairs(M.mru_index_map) do
    if M.buffer_order[index] ~= bufnr then
      vim.notify(string.format("MRU index map corruption detected: buffer %d at index %d", bufnr, index),
        vim.log.levels.ERROR)
      return false
    end
  end

  for i, bufnr in ipairs(M.buffer_order) do
    if M.mru_index_map[bufnr] ~= i then
      vim.notify(string.format("MRU buffer order corruption detected: buffer %d should be at index %d", bufnr, i),
        vim.log.levels.ERROR)
      return false
    end
  end

  return true
end

function M.rebuild_mru_index_map()
  M.mru_index_map = {}
  for i, bufnr in ipairs(M.buffer_order) do
    M.mru_index_map[bufnr] = i
  end
end

function M.identify_buffer_list(buffer_list)
  if buffer_list == M.buffer_order then
    return "mru"
  elseif buffer_list == M.tabline_order then
    return "tabline"
  else
    return "unknown"
  end
end

function M.get_buffer_mru_index(bufnr)
  return M.mru_index_map[bufnr]
end

function M.get_buffer_tabline_index(bufnr)
  return M.tabline_index_map[bufnr]
end

function M.reset_state()
  M.buffer_order = {}
  M.tabline_order = {}
  M.mru_index_map = {}
  M.cycle.is_active = false
  M.cycle.index = 0
end

return M
