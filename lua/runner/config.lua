-- In config.lua
local M = {}

-- Define language categories
M.LANGUAGE_TYPES = {
    COMPILED = "compiled",      -- Languages requiring compilation to binary
    ASSEMBLED = "assembled",    -- Languages requiring assembly step
    LINKED = "linked",          -- Languages requiring linking
    INTERPRETED = "interpreted" -- Languages run through interpreter
}

M.init = function(options)
    local defaults = {
        c = {
            type = { M.LANGUAGE_TYPES.COMPILED },
            compiler = "gcc",
            fallback_flags = { "-std=c23", "-O2" },
            response_file = nil,
            data_dir_name = "dat",
            output_directory = "/tmp/",
            run_command = nil,
        },

        cpp = {
            type = { M.LANGUAGE_TYPES.COMPILED },
            compiler = "g++",
            fallback_flags = { "-std=c++23", "-O2" },
            response_file = nil,
            data_dir_name = "dat",
            output_directory = "/tmp/",
            run_command = nil,
        },

        asm = {
            type = { M.LANGUAGE_TYPES.ASSEMBLED, M.LANGUAGE_TYPES.LINKED },
            compiler = "nasm",
            fallback_flags = { "-f", "elf64" },
            response_file = nil,
            data_dir_name = "dat",
            output_directory = "/tmp/",
            linker = "ld",
            linker_flags = { "-m", "elf_x86_64" },
            run_command = nil,
        },

        python = {
            type = { M.LANGUAGE_TYPES.INTERPRETED },
            compiler = nil,
            fallback_flags = {},
            response_file = nil,
            data_dir_name = "dat",
            output_directory = "",
            run_command = "python3",
        },

        lua = {
            type = { M.LANGUAGE_TYPES.INTERPRETED },
            compiler = nil,
            fallback_flags = {},
            response_file = nil,
            data_dir_name = "dat",
            output_directory = "",
            run_command = "lua",
        },
    }

    local config = vim.tbl_deep_extend('force', defaults, options or {})
    return config[vim.api.nvim_get_option_value("filetype", { buf = 0 })]
end

return M
