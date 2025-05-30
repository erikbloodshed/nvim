-- Create a new file: command_registry.lua
local M = {}

M.register = function(actions, state)
    local LANG_TYPES = require("runner.config").LANGUAGE_TYPES

    -- Helper to check if language belongs to a type
    local has_type = function(type)
        for _, lang_type in ipairs(state.language_types) do
            if lang_type == type then
                return true
            end
        end
        return false
    end

    -- Determine available command types based on language
    local commands = {
        -- Common commands for all language types
        { name = "RunnerRun",            action = actions.run,              desc = "Run the current file" },
        { name = "RunnerSetArgs",        action = actions.set_cmd_args,     desc = "Set command-line arguments" },
        { name = "RunnerAddDataFile",    action = actions.add_data_file,    desc = "Add a data file" },
        { name = "RunnerRemoveDataFile", action = actions.remove_data_file, desc = "Remove the current data file" },
        { name = "RunnerInfo",           action = actions.get_build_info,   desc = "Show build information" },
        { name = "RunnerProblems",       action = actions.open_quickfix,    desc = "Open quickfix window" },
    }

    -- Commands for compiled/assembled languages
    if has_type(LANG_TYPES.COMPILED) or has_type(LANG_TYPES.ASSEMBLED) then
        table.insert(commands, {
            name = "RunnerCompile",
            action = actions.compile,
            desc = "Compile the current file"
        })
    end

    -- Commands for compiled languages only
    if has_type(LANG_TYPES.COMPILED) and actions.show_assembly then
        table.insert(commands, {
            name = "RunnerShowAssembly",
            action = actions.show_assembly,
            desc = "Show assembly output"
        })
    end

    -- Register commands
    if vim.api.nvim_create_user_command then
        for _, cmd in ipairs(commands) do
            vim.api.nvim_create_user_command(cmd.name, cmd.action, { desc = cmd.desc })
        end
    end

    -- Register key mappings if configured
    if state.keymaps then
        for _, mapping in ipairs(state.keymaps) do
            if mapping.action and actions[mapping.action] then
                vim.keymap.set(
                    mapping.mode or "n",
                    mapping.key,
                    actions[mapping.action],
                    { buffer = 0, desc = mapping.desc }
                )
            end
        end
    end
end

return M
