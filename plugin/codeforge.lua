vim.api.nvim_create_augroup("codeforge", { clear = true })
vim.api.nvim_create_autocmd("Filetype", {
    group = "codeforge",
    pattern = { "c", "cpp", "asm" },
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
        local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })

        if ft == "cpp" or ft == "c" or ft == "asm" then
            keyset("n", "<leader>rc", function() build.compile() end, arg)
            if ft == "cpp" or ft == "c" then
                keyset("n", "<leader>ra", function() build.show_assembly() end, arg)
            end
        end

        keyset("n", "<leader>rr", function() build.run() end, arg)
        keyset("n", "<leader>da", function() build.add_data_file() end, arg)
        keyset("n", "<leader>dr", function() build.remove_data_file() end, arg)
        keyset("n", "<leader>sa", function() build.set_cmd_args() end, arg)
        keyset({ "n", "i" }, "<leader>bi", function() build.get_build_info() end, arg)
    end,
})
