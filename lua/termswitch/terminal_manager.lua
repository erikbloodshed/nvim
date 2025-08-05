-- termswitch/terminal_manager.lua
local Terminal = require('termswitch.terminal').Terminal

local M = {}
local terminals = {}
local default_config_cache = {}

--- Caches the user's default config to be applied to all terminals.
---@param user_config table
function M.cache_defaults(user_config)
    default_config_cache = user_config or {}
end

--- Creates and stores a new terminal instance.
---@param name string The unique name for the terminal.
---@param config table The specific configuration for this terminal.
---@return table The created terminal object.
function M.create_terminal(name, config)
    if terminals[name] then
        vim.notify(string.format("Terminal '%s' already exists", name), vim.log.levels.WARN)
        return terminals[name]
    end

    -- Merge the cached defaults with the specific terminal config
    local final_config = vim.tbl_extend('force', default_config_cache, config or {})
    terminals[name] = Terminal:new(name, final_config)
    return terminals[name]
end

--- Retrieves a terminal by its name.
---@param name string
---@return table|nil
function M.get_terminal(name)
    return terminals[name]
end

--- Removes a terminal and cleans up its resources.
---@param name string
---@return boolean True if removed, false if not found.
function M.remove_terminal(name)
    local terminal = terminals[name]
    if terminal then
        terminal:cleanup()
        terminals[name] = nil
        return true
    end
    return false
end

--- Returns a list of all current terminal names.
---@return string[]
function M.list_terminals()
    local names = {}
    for name in pairs(terminals) do
        table.insert(names, name)
    end
    table.sort(names) -- Sort for consistent ordering
    return names
end

--- Cleanup function for plugin unload.
function M.cleanup()
    for name in pairs(terminals) do
        M.remove_terminal(name)
    end
end

return M
