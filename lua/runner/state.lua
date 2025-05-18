-- Create a state object to hold all build-related data
local M = {}

M.init = function(config)
    local api = vim.api
    local fn = vim.fn
    local utils = require("runner.utils")

    local state = {
        filetype = api.nvim_get_option_value("filetype", { buf = 0 }),
        src_file = api.nvim_buf_get_name(0),
        src_basename = fn.expand("%:t:r"),
        is_compiled = config.is_compiled,
        compiler = config.compiler,
        compile_opts = utils.get_options_file(config.compile_opts) or config.fallback_flags,
        linker = config.linker,
        linker_flags = config.linker_flags or {},
        output_directory = config.output_directory or "",
        run_cmd = config.run_command,
        data_path = utils.get_data_path(config.data_dir_name),
        data_file = nil,
        cmd_args = nil,
        api = api,
        fn = fn,
        utils = utils
    }

    -- Initialize derived properties
    state.exe_file = state.output_directory .. state.src_basename
    state.asm_file = state.exe_file .. ".s"
    state.obj_file = state.exe_file .. ".o"

    state.hash_tbl = {
        compile = nil,
        assemble = nil,
        link = nil,
    }

    -- Command cache
    state.command_cache = {
        compile_cmd = nil,
        compile_signature = nil,
        link_cmd = nil,
        link_signature = nil,
        assemble_cmd = nil,
        assemble_signature = nil
    }

    -- Base command template
    state.cmd_template = {
        compiler = nil,
        arg = nil,
        timeout = 15000,
        kill_delay = 3000
    }

    return state
end

return M
