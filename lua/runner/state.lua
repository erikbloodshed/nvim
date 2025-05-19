-- In state.lua
local M = {}

M.init = function(opts)
    local prealloc = require("table.new")
    local api = vim.api
    local fn = vim.fn
    local utils = require("runner.utils")

    local x = prealloc(0, 24)
    x.filetype = api.nvim_get_option_value("filetype", { buf = 0 })
    x.src_file = api.nvim_buf_get_name(0)
    x.src_basename = fn.expand("%:t:r")
    x.language_types = opts.type or {}     -- Store language type
    x.compiler = opts.compiler
    x.response_file = utils.get_response_file(opts.response_file) or opts.fallback_flags
    x.linker = opts.linker
    x.linker_flags = opts.linker_flags or {}
    x.output_directory = opts.output_directory or ""
    x.run_cmd = opts.run_command
    x.data_path = utils.get_data_path(opts.data_dir_name)
    x.data_file = nil
    x.cmd_args = nil
    x.keymaps = opts.keymaps
    x.api = api
    x.fn = fn
    x.utils = utils

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
