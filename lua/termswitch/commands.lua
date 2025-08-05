local api = vim.api

local M = {}

function M.setup(terminal_manager)
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

    local convenience_commands = {
        {
            name = 'ToggleTerm',
            getter = terminal_manager.get_default_terminal,
            desc = 'Toggle floating terminal window'
        },
        {
            name = 'TogglePython',
            getter = terminal_manager.get_python_terminal,
            desc = 'Toggle floating Python interpreter'
        },
    }

    for _, cmd in ipairs(convenience_commands) do
        api.nvim_create_user_command(cmd.name, function()
            local terminal = cmd.getter()
            if terminal then
                terminal:toggle()
            else
                vim.notify(string.format("Terminal for %s not found", cmd.name), vim.log.levels.ERROR)
            end
        end, { desc = cmd.desc })
    end

    api.nvim_create_user_command('SendToTerm', function(opts)
        local terminal = terminal_manager.get_default_terminal()
        if not terminal then
            vim.notify("Default terminal not found", vim.log.levels.ERROR)
            return
        end

        if not terminal:is_running() then
            vim.notify("Default terminal is not running", vim.log.levels.WARN)
            return
        end

        local success = terminal:send(opts.args .. '\n')
        if success then
            vim.notify("Sent to default terminal: " .. opts.args, vim.log.levels.INFO)
        else
            vim.notify("Failed to send text to default terminal", vim.log.levels.ERROR)
        end
    end, {
        nargs = '+',
        desc = 'Send text to default terminal',
    })
end

return M
