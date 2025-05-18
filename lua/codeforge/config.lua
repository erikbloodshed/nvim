local get_options_file = function(filename)
    if filename then
        local path = vim.fs.find(filename, {
            upward = true,
            type = "file",
            path = vim.fn.expand("%:p:h"),
            stop = vim.fn.expand("~"),
        })[1]

        if path then
            return { "@" .. path }
        end
    end

    return nil
end

return {
    init = function(options)
        local config = {
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

        config = vim.tbl_deep_extend('force', config, options or {})

        local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })

        local compile_opts = config[ft].compile_opts
        local fallback = config[ft].fallback_flags

        config[ft].compile_opts = compile_opts and get_options_file(compile_opts) or fallback

        return config[ft]
    end
}
