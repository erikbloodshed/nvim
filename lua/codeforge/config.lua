local M = {}

local defaults = {
    c = {
        compiler         = "gcc",
        fallback_flags   = { "-std=c23", "-O2" },
        compile_opts     = nil,
        data_dir_name    = "dat",
        output_directory = "/tmp/",
        is_compiled      = true,
        run_command      = nil,
    },

    cpp = {
        compiler         = "g++",
        fallback_flags   = { "-std=c++23", "-O2" },
        compile_opts     = nil,
        data_dir_name    = "dat",
        output_directory = "/tmp/",
        is_compiled      = true,
        run_command      = nil,
    },

    asm = {
        compiler         = "nasm",
        fallback_flags   = { "-f", "elf64" },
        compile_opts     = nil,
        data_dir_name    = "dat",
        output_directory = "/tmp/",
        is_compiled      = true,
        linker           = "ld",
        linker_flags     = { "-m", "elf_x86_64" },
        run_command      = nil,
    },

    python = {
        compiler         = "python3",
        fallback_flags   = {},
        compile_opts     = nil,
        data_dir_name    = "dat",
        output_directory = "",
        is_compiled      = false,
        run_command      = "python3",
    },

    lua = {
        compiler         = "lua",
        fallback_flags   = {},
        compile_opts     = nil,
        data_dir_name    = "dat",
        output_directory = "",
        is_compiled      = false,
        run_command      = "lua",
    },
}

M.init = function(options)
    local config = vim.tbl_deep_extend('force', defaults, options or {})
    local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })

    return config[ft]
end

return M
