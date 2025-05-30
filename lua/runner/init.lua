-- Final init.lua
local M = {}

-- Validate config
local function validate_config(config)
    assert(config, "Configuration is required")
    assert(config.type, "Language type must be specified")

    local LANG_TYPES = require("runner.config").LANGUAGE_TYPES

    local has_type = function(type)
        for _, lang_type in ipairs(config.type) do
            if lang_type == type then
                return true
            end
        end
        return false
    end

    if has_type(LANG_TYPES.COMPILED) or has_type(LANG_TYPES.ASSEMBLED) then
        assert(config.compiler, "Compiler must be specified for compiled/assembled languages")
        assert(config.output_directory ~= nil, "Output directory must be specified")
    end

    if has_type(LANG_TYPES.LINKED) then
        assert(config.linker, "Linker must be specified for languages that require linking")
    end

    if has_type(LANG_TYPES.INTERPRETED) then
        assert(config.run_command, "Run command must be specified for interpreted languages")
    end

    -- Ensure output directory ends with a path separator
    if config.output_directory and #config.output_directory > 0 then
        local last_char = config.output_directory:sub(-1)
        if last_char ~= "/" and last_char ~= "\\" then
            config.output_directory = config.output_directory .. "/"
        end
    end

    return config
end

M.setup = function(opts)
    local config = require("runner.config").init(opts)

    -- Skip if no configuration for this filetype
    if not config then
        vim.notify("No runner configuration for filetype: " .. vim.api.nvim_get_option_value("filetype", { buf = 0 }),
            vim.log.levels.WARN)
        return {}
    end

    -- Initialize modules
    local state = require("runner.state").init(validate_config(config))
    local commands = require("runner.commands").create(state)
    local handler = require("runner.handler")
    local actions = require("runner.actions").create(state, commands, handler)

    -- Register commands
    require("runner.command_registry").register(actions, state)
end

return M
