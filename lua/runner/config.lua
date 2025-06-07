-- In config.lua
local M = {}

-- Define language categories
M.LANGUAGE_TYPES = {
    COMPILED = "compiled",      -- Languages requiring compilation to binary
    ASSEMBLED = "assembled",    -- Languages requiring assembly step
    LINKED = "linked",          -- Languages requiring linking
    INTERPRETED = "interpreted" -- Languages run through interpreter
}

M.init = function(user_config)
    local defaults = {
        keymaps = {
            { key = "<leader>rr", action = "run",              mode = "n", desc = "Runner: Run File" },
            { key = "<leader>rc", action = "compile",          mode = "n", desc = "Runner: Compile File" },
            { key = "<leader>ra", action = "set_cmd_args",     mode = "n", desc = "Runner: Set Arguments" },
            { key = "<leader>ri", action = "get_build_info",   mode = "n", desc = "Runner: Show Build Info" },
            { key = "<leader>rd", action = "add_data_file",    mode = "n", desc = "Runner: Add Data File" },
            { key = "<leader>rx", action = "remove_data_file", mode = "n", desc = "Runner: Remove Data File" },
            { key = "<leader>rs", action = "show_assembly",    mode = "n", desc = "Runner: Show Assembly" },
            { key = "<leader>rq", action = "open_quickfix",    mode = "n", desc = "Runner: Open Quickfix" },
        },

        filetype = {
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
                fallback_flags = { "-std=c++20", "-O2" },
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
    }

    local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })

    if not defaults.filetype[ft] then
        vim.notify("No default configuration found for filetype: " .. ft, vim.log.levels.ERROR)
        return nil
    end

    local lang_config = {}
    if user_config and user_config.filetype and user_config.filetype[ft] then
        lang_config = user_config.filetype[ft]
    end

    local config = vim.tbl_deep_extend('force', defaults.filetype[ft], lang_config)

    local keymaps = defaults.keymaps
    if user_config and user_config.keymaps then
        keymaps = vim.tbl_deep_extend("force", keymaps, user_config.keymaps)
    end

    config.keymaps = keymaps

    return config
end

return M
