local keyset = vim.keymap.set
local autocmd = vim.api.nvim_create_autocmd

local group_id = vim.api.nvim_create_augroup("Runner", { clear = true })
autocmd("Filetype", {
    group = group_id,
    pattern = { "c", "cpp", "asm", "python", "lua" },
    callback = function(args)
        local build = require("runner").setup({
            cpp = {
                compiler = "g++-15",
                compile_opts = ".compile_flags",
            }
        })

        local arg = { buffer = args.buf, noremap = true }

        keyset("n", "<leader>rc", function() build.compile() end, arg)
        keyset("n", "<leader>ra", function() build.show_assembly() end, arg)
        keyset("n", "<leader>rr", function() build.run() end, arg)
        keyset("n", "<leader>da", function() build.add_data_file() end, arg)
        keyset("n", "<leader>dr", function() build.remove_data_file() end, arg)
        keyset("n", "<leader>sa", function() build.set_cmd_args() end, arg)
        keyset("n", "<leader>bi", function() build.get_build_info() end, arg)
        keyset("n", "<leader>xx", function() require("diagnostics").open_quickfixlist() end, arg)
    end,
})

autocmd("Filetype", {
    pattern = { "help", "qf" },
    callback = function(args)
        keyset("n", "q", function() vim.cmd.bdelete() end, { buffer = args.buf, silent = true, noremap = true })
    end,
})

autocmd({ "BufEnter" }, {
    callback = function()
        require("custom_ui.input")
        require("custom_ui.select")

        local bufswitch = require("bufferswitch")

        keyset('n', "<Right>", function() bufswitch.goto_next_buffer() end,
            { noremap = true, silent = true })
        keyset('n', "<Left>", function() bufswitch.goto_prev_buffer() end,
            { noremap = true, silent = true })
        keyset("n", "<leader>ot", function()
                local original_directory = vim.fn.getcwd()
                local current_file = vim.api.nvim_buf_get_name(0)
                local directory = current_file ~= "" and vim.fn.fnamemodify(current_file, ":h")
                    or original_directory

                vim.cmd("cd " .. directory .. " | term")

                vim.api.nvim_create_autocmd("TermClose", {
                    callback = function()
                        vim.cmd("cd " .. original_directory)
                    end,
                })
            end,
            { noremap = true, silent = true, nowait = true })
    end,
})

autocmd("Filetype", {
    pattern = { "c", "cpp" },
    callback = function()
        vim.opt_local.cinkeys:remove(":")
        vim.opt_local.cindent = true
    end,
})

autocmd({ "TermOpen" }, {
    pattern = { "*" },
    callback = function()
        vim.cmd.startinsert()
    end,
})

autocmd("LspAttach", {
    callback = function(args)
        local x = vim.diagnostic.severity

        vim.diagnostic.config({
            virtual_text = false,
            severity_sort = true,
            float = { border = "rounded" },
            signs = {
                text = { [x.ERROR] = "", [x.WARN]  = "󱈸", [x.HINT]  = "", [x.INFO]  = "", },
            },
        })


        local opts = { buffer = args.buf }
        keyset("n", "<leader>ed", vim.diagnostic.open_float, opts)
        keyset("n", "<leader>gi", vim.lsp.buf.implementation, opts)
        keyset("n", "<leader>gd", vim.lsp.buf.definition, opts)
        keyset("n", "<leader>rn", vim.lsp.buf.rename, opts)
        keyset("n", "<leader>fc", function()
            vim.lsp.buf.format({ async = true })
        end, opts)
    end,
})
