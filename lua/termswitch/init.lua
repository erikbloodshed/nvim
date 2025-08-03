local M = {}

local terminal_manager = require('termswitch.terminal_manager')
local commands = require('termswitch.commands')
local keymaps = require('termswitch.keymaps')

function M.setup(user_config)
    terminal_manager.setup(user_config)
    commands.setup(terminal_manager)
    keymaps.setup(terminal_manager)
end

M.create_terminal = terminal_manager.create_terminal
M.get_terminal = terminal_manager.get_terminal
M.remove_terminal = terminal_manager.remove_terminal
M.list_terminals = terminal_manager.list_terminals
M.cleanup = terminal_manager.cleanup
M.Terminal = require('termswitch.terminal').Terminal

return M
