local M = {}

M.defaults = {
  keymaps = {},
  filetype = {
    c = {
      execution_model = "compiled",
      compiler = "gcc",
      compiler_flags = { "-std=c23", "-O2" },
      response_file = nil,
      output_dir = "/tmp/",
      data_dir_name = nil,
    },

    cpp = {
      execution_model = "compiled",
      compiler = "g++",
      compiler_flags = { "-std=c++20", "-O2" },
      response_file = nil,
      output_dir = "/tmp/",
      data_dir_name = nil,
    },

    asm = {
      execution_model = "assembled",
      assembler = "nasm",
      assembler_flags = { "-f", "elf64" },
      response_file = nil,
      linker = "ld",
      linker_flags = { "-m", "elf_x86_64" },
      output_dir = "/tmp/",
      data_dir_name = nil,
    },

    python = {
      execution_model = "interpreted",
      interpreter = "python3",
      interpreter_flags = {},
      data_dir_name = nil,
    },

    lua = {
      execution_model = "interpreted",
      interpreter = "lua",
      interpreter_flags = {},
      data_dir_name = nil,
    },
  }
}

return M
