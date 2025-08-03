local api = vim.api
local keyset = vim.keymap.set
local autocmd = api.nvim_create_autocmd

autocmd({ "Filetype" }, {
    pattern = { "c", "cpp", "asm", "python", "lua" },

    callback = function(args)
        local ft = api.nvim_get_option_value("filetype", { buf = args.buf })

        if ft == "cpp" or ft == "c" then
            vim.opt_local.cinkeys:remove(":")
            vim.opt_local.cindent = true
        end

        require("runner").setup({
            filetype = {
                c = {
                    response_file = ".compile_flags",
                },
                cpp = {
                    response_file = ".compile_flags",
                },
                python = {
                    run_command = "python3.14"
                }
            }
        })
    end,
})

autocmd({ "Filetype" }, {
    pattern = { "help", "qf" },
    callback = function(args)
        keyset("n", "q", function() vim.cmd.bdelete() end, { buffer = args.buf, silent = true, noremap = true })
    end,
})

autocmd({ "VimEnter" }, {
    callback = function()
        require("custom_ui.input")
        require("custom_ui.select")
        require("termswitch").setup()

        keyset('n', "<Right>", function() require("bufferswitch").goto_next_buffer() end, { noremap = true, silent = true })
        keyset('n', "<Left>", function() require("bufferswitch").goto_prev_buffer() end, { noremap = true, silent = true })
    end,
})

autocmd({ "TermOpen" }, {
    pattern = { "*" },
    callback = function()
        vim.cmd.startinsert()
    end,
})
