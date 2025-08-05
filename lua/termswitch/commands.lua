-- termswitch/commands.lua
local api = vim.api

local M = {}

--- Sets up user commands.
---@param terminal_manager table The terminal manager module.
---@param user_commands table A list of command configurations.
function M.setup(terminal_manager, user_commands)
    -- Generic command to toggle any terminal by its name
    api.nvim_create_user_command('ToggleTerminal', function(opts)
        local name = opts.args
        if name == '' then
            vim.notify("Usage: :ToggleTerminal <terminal_name>", vim.log.levels.ERROR)
            return
        end

        local term = terminal_manager.get_terminal(name)
        if not term then
            vim.notify(string.format("Terminal '%s' not found. Create it first.", name), vim.log.levels.ERROR)
            return
        end

        term:toggle()
    end, {
        nargs = 1,
        complete = terminal_manager.list_terminals,
        desc = 'Toggle any terminal by name',
    })

    -- Create user-defined convenience commands
    if not user_commands or type(user_commands) ~= 'table' then
        return
    end

    for _, cmd_config in ipairs(user_commands) do
        local cmd_name = cmd_config.name
        local term_name = cmd_config.terminal

        if not cmd_name or not term_name then
            vim.notify("TermSwitch: Invalid command config. Requires 'name' and 'terminal'.", vim.log.levels.WARN)
            goto continue
        end

        api.nvim_create_user_command(cmd_name, function()
            local terminal = terminal_manager.get_terminal(term_name)
            if terminal then
                terminal:toggle()
            else
                vim.notify(string.format("Terminal '%s' not found for command '%s'", term_name, cmd_name),
                    vim.log.levels.ERROR)
            end
        end, {
            desc = cmd_config.desc or string.format("Toggle the '%s' terminal", term_name)
        })

        ::continue::
    end
end

return M
