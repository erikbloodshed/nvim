local M = {}

function M.setup(config)
  config = config or {}

  local term_manager = require('term.manager')
  term_manager.cache_defaults(config.defaults)

  if config.terminals and type(config.terminals) == 'table' then
    for name, term_config in pairs(config.terminals) do
      term_manager.create_terminal(name, term_config)
    end
  end

  -- Always set up built-in commands (ToggleTerminal, Run) regardless of
  -- whether the user supplied a commands table. Previously this block was
  -- gated on `#config.commands > 0`, which silently skipped those commands
  -- for users who had no custom commands configured.
  local commands = require('term.commands')
  commands.setup(term_manager, config.commands)

  if config.keymaps and #config.keymaps > 0 then
    local keymaps = require('term.keymaps')
    keymaps.setup(term_manager, config.keymaps)
  end
end

return M
