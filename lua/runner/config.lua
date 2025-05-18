local M = {}

M.init = function(options)
    local defaults = {
        c = {
            compiler         = "gcc",
            fallback_flags   = { "-std=c23", "-O2" },
            reponse_file     = nil,
            data_dir_name    = "dat",
            output_directory = "/tmp/",
            is_compiled      = true,
            run_command      = nil,
        },

        cpp = {
            compiler         = "g++",
            fallback_flags   = { "-std=c++23", "-O2" },
            reponse_file     = nil,
            data_dir_name    = "dat",
            output_directory = "/tmp/",
            is_compiled      = true,
            run_command      = nil,
        },

        asm = {
            compiler         = "nasm",
            fallback_flags   = { "-f", "elf64" },
            response_file     = nil,
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
            response_file     = nil,
            data_dir_name    = "dat",
            output_directory = "",
            is_compiled      = false,
            run_command      = "python3",
        },

        lua = {
            compiler         = "lua",
            fallback_flags   = {},
            response_file     = nil,
            data_dir_name    = "dat",
            output_directory = "",
            is_compiled      = false,
            run_command      = "lua",
        },
    }

    local config = vim.tbl_deep_extend('force', defaults, options or {})
    return config[vim.api.nvim_get_option_value("filetype", { buf = 0 })]
end

return M
