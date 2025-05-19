-- In state.lua
local M = {}

M.init = function(config)
    local api = vim.api
    local fn = vim.fn
    local utils = require("runner.utils")

    local x = {
        filetype = api.nvim_get_option_value("filetype", { buf = 0 }),
        src_file = api.nvim_buf_get_name(0),
        src_basename = fn.expand("%:t:r"),
        language_types = config.type or {}, -- Store language types
        compiler = config.compiler,
        response_file = utils.get_response_file(config.response_file) or config.fallback_flags,
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

    x.exe_file = x.output_directory .. x.src_basename
    x.asm_file = x.exe_file .. ".s"
    x.obj_file = x.exe_file .. ".o"

    x.hash_tbl = {
        compile = nil,
        assemble = nil,
        link = nil,
    }

    x.command_cache = {
        compile_cmd = nil,
        link_cmd = nil,
        assemble_cmd = nil,
    }

    x.cmd_template = {
        compiler = nil,
        arg = nil,
        timeout = 15000,
        kill_delay = 3000
    }

    return x
end

return M
