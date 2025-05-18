local M = {}

-- Validate the configuration
local function validate_config(config)
    assert(config, "Configuration is required")

    if config.is_compiled then
        assert(config.compiler, "Compiler must be specified for compiled languages")
        assert(config.output_directory, "Output directory must be specified")
    else
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
    local state = require("runner.state").init(validate_config(config))
    local commands = require("runner.commands").create(state)
    local handler = require("runner.handler")
    local actions = require("runner.actions").create(state, commands, handler)

    return actions
end

return M
