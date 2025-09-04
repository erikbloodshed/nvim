local M = {}

M.init = function(config)
  local api = vim.api
  local fn = vim.fn
  local utils = require("runner.utils")

  local state = {
    filetype = config.filetype,
    src_file = api.nvim_buf_get_name(0),
    type = config.type,
    compiler = config.compiler,
    compiler_flags = utils.get_response_file(config.response_file) or config.fallback_flags,
    linker = config.linker,
    linker_flags = config.linker_flags or {},
    output_directory = config.output_directory or "",
    data_path = utils.get_data_path(config.data_dir_name),
    data_file = nil,
    cmd_args = nil,
    keymaps = config.keymaps,
    api = api,
    fn = fn,
    utils = utils,

    hash_tbl = {
      compile = nil,
      assemble = nil,
      link = nil,
    },

    command_cache = {
      compile_cmd = nil,
      link_cmd = nil,
      show_assembly_cmd = nil,
      interpret_cmd = nil,
      run_cmd = nil,
    },

    timeout = 15000,
    kill_delay = 3000,
  }

  state.src_basename = vim.fn.fnamemodify(state.src_file, ":t:r")
  state.exe_file = state.output_directory .. state.src_basename
  state.asm_file = state.exe_file .. ".s"
  state.obj_file = state.exe_file .. ".o"
  state.has_type = function(t) return state.type == t end

  return state
end

return M
