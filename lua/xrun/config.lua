return {
  keymaps = {
    { mode = "n", key = "<leader>rr", action = "run", desc = "Run File" },
    { mode = "n", key = "<leader>ra", action = "set_cmd_args", desc = "Set Arguments" },
    { mode = "n", key = "<leader>rf", action = "set_compiler_flags", desc = "Set Compiler Flags" },
    { mode = "n", key = "<leader>rq", action = "open_quickfix", desc = "Open Quickfix" },
    { mode = "n", key = "<leader>rd", action = "add_data_file", desc = "Add Data File" },
    { mode = "n", key = "<leader>rx", action = "remove_data_file", desc = "Remove Data File" },
    { mode = "n", key = "<leader>rs", action = "show_assembly", desc = "Show Assembly" },
    { mode = "n", key = "<leader>ri", action = "get_build_info", desc = "Show Build Info" },
  },

  filetype = {
    c = {
      type = "compiled",
      compiler = "gcc",
      fallback_flags = { "-std=c23", "-O2" },
      response_file = nil,
      data_dir_name = "dat",
      output_directory = "/tmp",
    },

    cpp = {
      type = "compiled",
      compiler = "g++",
      fallback_flags = { "-std=c++20", "-O2" },
      response_file = nil,
      data_dir_name = "dat",
      output_directory = "/tmp",
    },

    asm = {
      type = "assembled",
      compiler = "nasm",
      fallback_flags = { "-f", "elf64" },
      response_file = nil,
      linker = "ld",
      linker_flags = { "-m", "elf_x86_64" },
      data_dir_name = "dat",
      output_directory = "/tmp",
    },

    python = {
      type = "interpreted",
      compiler = "python3",
      fallback_flags = {},
      response_file = nil,
      data_dir_name = "dat",
    },

    lua = {
      type = "interpreted",
      compiler = "lua",
      fallback_flags = {},
      response_file = nil,
      data_dir_name = "dat",
    },
  }
}
