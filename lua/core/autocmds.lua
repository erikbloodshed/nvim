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

autocmd({ "BufEnter" }, {
    callback = function()
        require("custom_ui.input")
        require("custom_ui.select")
        require("termswitch").setup()
        require("python").init()

        local bufswitch = require("bufferswitch")

        keyset('n', "<Right>", function() bufswitch.goto_next_buffer() end, { noremap = true, silent = true })
        keyset('n', "<Left>", function() bufswitch.goto_prev_buffer() end, { noremap = true, silent = true })

        keyset("n", "<leader>ot", function()
            local original_directory = vim.fn.getcwd()
            local current_file = api.nvim_buf_get_name(0)
            local directory = current_file ~= "" and vim.fn.fnamemodify(current_file, ":h")
                or original_directory

            vim.cmd("cd " .. directory .. " | term")

            api.nvim_create_autocmd("TermClose", {
                callback = function()
                    vim.cmd("cd " .. original_directory)
                end,
            })
        end, { noremap = true, silent = true, nowait = true })
    end,
})

autocmd({ "TermOpen" }, {
    pattern = { "*" },
    callback = function()
        vim.cmd.startinsert()
    end,
})
