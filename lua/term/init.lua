local M = {}
local _term_manager
local _commands
local _keymaps

local function get_terminal_manager()
  if not _term_manager then
    _term_manager = require('term.manager')
  end
  return _term_manager
end

function M.setup(config)
  config = config or {}

  local term_manager = get_terminal_manager()
  term_manager.cache_defaults(config.defaults)

  if config.terminals and type(config.terminals) == 'table' then
    for name, term_config in pairs(config.terminals) do
      term_manager.create_terminal(name, term_config)
    end
  end

  if config.commands and #config.commands > 0 then
    if not _commands then
      _commands = require('term.commands')
    end
    _commands.setup(term_manager, config.commands)
  end

  if config.keymaps and #config.keymaps > 0 then
    if not _keymaps then
      _keymaps = require('term.keymaps')
    end
    _keymaps.setup(term_manager, config.keymaps)
  end
end

return M
