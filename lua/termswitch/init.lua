local M = {}
local _terminal_manager
local _commands
local _keymaps

local function get_terminal_manager()
  if not _terminal_manager then
    _terminal_manager = require('termswitch.terminal_manager')
  end
  return _terminal_manager
end

function M.setup(config)
  config = config or {}

  local terminal_manager = get_terminal_manager()
  terminal_manager.cache_defaults(config.defaults)

  if config.terminals and type(config.terminals) == 'table' then
    for name, term_config in pairs(config.terminals) do
      terminal_manager.create_terminal(name, term_config)
    end
  end

  if config.commands and #config.commands > 0 then
    if not _commands then
      _commands = require('termswitch.commands')
    end
    _commands.setup(terminal_manager, config.commands)
  end

  if config.keymaps and #config.keymaps > 0 then
    if not _keymaps then
      _keymaps = require('termswitch.keymaps')
    end
    _keymaps.setup(terminal_manager, config.keymaps)
  end
end

return M
