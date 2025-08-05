local Terminal = require('termswitch.terminal').Terminal

local M = {}
local terminals = {}
local default_config = {}

function M.setup(user_config)
    default_config = user_config or {}

    M.create_terminal('terminal', default_config)

    local python_config = vim.tbl_extend('force', default_config, {
        shell = 'python3.14',
        filetype = 'pyterm',
        auto_delete_on_close = true,
    })
    M.create_terminal('python', python_config)
end

function M.create_terminal(name, config)
    if terminals[name] then
        vim.notify(string.format("Terminal '%s' already exists", name), vim.log.levels.WARN)
        return terminals[name]
    end

    terminals[name] = Terminal:new(name, config or {})
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
    table.sort(names) -- Sort for consistent ordering
    return names
end

-- Cleanup function for plugin unload
function M.cleanup()
    for name in pairs(terminals) do
        M.remove_terminal(name)
    end
end

-- Get default terminals for commands/keymaps
function M.get_default_terminal()
    return terminals['terminal']
end

function M.get_python_terminal()
    return terminals['python']
end

return M
