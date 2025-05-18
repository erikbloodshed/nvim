local group_id = vim.api.nvim_create_augroup("CodeForge", { clear = true })
vim.api.nvim_create_autocmd("Filetype", {
    group = group_id,
    pattern = { "c", "cpp", "asm", "python", "lua" },
    callback = function(args)
        local keyset = vim.keymap.set

        local config = require("codeforge.config").init({
            cpp = {
                compiler = "g++-15",
                compile_opts = ".compile_flags",
            }
        })

        local build = require("codeforge.build").init(config)
        local arg = { buffer = args.buf, noremap = true }

        keyset("n", "<leader>rc", function() build.compile() end, arg)
        keyset("n", "<leader>ra", function() build.show_assembly() end, arg)
        keyset("n", "<leader>rr", function() build.run() end, arg)
        keyset("n", "<leader>da", function() build.add_data_file() end, arg)
        keyset("n", "<leader>dr", function() build.remove_data_file() end, arg)
        keyset("n", "<leader>sa", function() build.set_cmd_args() end, arg)
        keyset("n", "<leader>bi", function() build.get_build_info() end, arg)
    end,
})
