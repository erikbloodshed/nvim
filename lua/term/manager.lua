local Terminal = require('term.terminal').Terminal
local api = vim.api

local M = {}
local terminals = {}
local default_config_cache = {}
local manager_events_setup = false

local function setup_manager_events()
  if manager_events_setup then return end

  api.nvim_create_autocmd('VimLeavePre', {
    group = api.nvim_create_augroup('TerminalManager', { clear = true }),
    callback = M.cleanup,
    desc = 'Cleanup all terminals on exit'
  })

  manager_events_setup = true
end

function M.cache_defaults(user_config)
  default_config_cache = user_config or {}
  setup_manager_events()
end

function M.create_terminal(name, config)
  if terminals[name] then
    vim.notify(string.format("Terminal '%s' already exists", name), vim.log.levels.WARN)
    return terminals[name]
  end

  local final_config = vim.tbl_extend('force', default_config_cache, config or {})
  terminals[name] = Terminal:new(name, final_config)
  return terminals[name]
end

function M.get_terminal(name)
  return terminals[name]
end

function M.remove_terminal(name)
  local terminal = terminals[name]
  if terminal then
    terminal:cleanup()
    terminals[name] = nil
    return true
  end
  return false
end

function M.list_terminals()
  local names = {}
  for name in pairs(terminals) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

function M.cleanup()
  for name in pairs(terminals) do
    M.remove_terminal(name)
  end
end

return M
