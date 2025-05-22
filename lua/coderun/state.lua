-- In state.lua
local M = {}

M.init = function(config)
    local prealloc = require("table.new")
    local api = vim.api
    local fn = vim.fn
    local utils = require("runner.utils")

    local x = prealloc(0, 24)
    x.filetype = api.nvim_get_option_value("filetype", { buf = 0 })
    x.src_file = api.nvim_buf_get_name(0)
    x.src_basename = fn.expand("%:t:r")
    x.language_types = config.type or {}     -- Store language type
    x.compiler = config.compiler
    x.compiler_flags = utils.get_response_file(config.response_file) or config.fallback_flags
    x.linker = config.linker
    x.linker_flags = config.linker_flags or {}
    x.output_directory = config.output_directory or ""
    x.run_cmd = config.run_command
    x.data_path = utils.get_data_path(config.data_dir_name)
    x.data_file = nil
    x.cmd_args = nil
    x.keymaps = config.keymaps
    x.api = api
    x.fn = fn
    x.utils = utils

    x.compile_command = vim.list_extend({ x. compiler }, x.compiler_flags)

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
