-- In state.lua
local M = {}

M.init = function(config)
    local prealloc = require("table.new")
    local api = vim.api
    local fn = vim.fn
    local utils = require("runner.utils")

    local state = prealloc(0, 24)
    state.filetype = api.nvim_get_option_value("filetype", { buf = 0 })
    state.src_file = api.nvim_buf_get_name(0)
    state.language_types = config.type or {}
    state.compiler = config.compiler
    state.compiler_flags = utils.get_response_file(config.response_file) or config.fallback_flags
    state.linker = config.linker
    state.linker_flags = config.linker_flags or {}
    state.output_directory = config.output_directory or ""
    state.run_cmd = config.run_command
    state.data_path = utils.get_data_path(config.data_dir_name)
    state.data_file = nil
    state.cmd_args = nil
    state.keymaps = config.keymaps
    state.api = api
    state.fn = fn
    state.utils = utils

    state.src_basename = vim.fn.fnamemodify(state.src_file, ":t:r")
    state.exe_file = state.output_directory .. state.src_basename
    state.asm_file = state.exe_file .. ".s"
    state.obj_file = state.exe_file .. ".o"

    state.hash_tbl = prealloc(0, 3)
    state.hash_tbl.compile = nil
    state.hash_tbl.assemble = nil
    state.hash_tbl.link = nil

    state.command_cache = prealloc(0, 3)
    state.command_cache.compile_cmd = nil
    state.command_cache.link_cmd = nil
    state.command_cache.assemble_cmd = nil

    state.cmd_template = prealloc(0, 4)
    state.cmd_template.compiler = nil
    state.cmd_template.arg = nil
    state.cmd_template.timeout = 15000
    state.cmd_template.kill_delay = 3000

    return state
end

return M
