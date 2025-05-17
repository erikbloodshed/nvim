local keyset = vim.keymap.set
local autocmd = vim.api.nvim_create_autocmd

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
    callback = function(args)
        vim.opt_local.cinkeys:remove(":")
        vim.opt_local.cindent = true

        local config = require("codeforge.config").init({
            cpp = {
                compiler = "g++-15",
                compile_opts = ".compile_flags",
            }
        })

        local build = require("codeforge.build").init(config)
        local arg = { buffer = args.buf, noremap = true }

        keyset("n", "<leader>rc", function() build.compile() end, arg)
        keyset("n", "<leader>rr", function() build.run() end, arg)
        keyset("n", "<leader>ra", function() build.show_assembly() end, arg)
        keyset("n", "<leader>da", function() build.add_data_file() end, arg)
        keyset("n", "<leader>dr", function() build.remove_data_file() end, arg)
        keyset("n", "<leader>sa", function() build.set_cmd_args() end, arg)
        keyset({ "n", "i" }, "<leader>bi", function() build.get_build_info() end, arg)
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
        local diag = vim.diagnostic

        -- Configure Neovim's built-in diagnostics
        diag.config({
            virtual_text = false,           -- Disable virtual text diagnostics
            severity_sort = true,           -- Sort diagnostics by severity
            float = { border = "rounded" }, -- Set rounded border for diagnostic float window
            signs = {                       -- Define custom text signs for different severity levels
                text = {
                    [diag.severity.ERROR] = "",
                    [diag.severity.WARN]  = "󱈸",
                    [diag.severity.HINT]  = "",
                    [diag.severity.INFO]  = "",
                },
            },
        })

        local diagnostics = require("diagnostics")

        local opts = { buffer = args.buf }
        keyset("n", "<leader>ed", diag.open_float, opts)
        keyset("n", "<leader>gi", vim.lsp.buf.implementation, opts)
        keyset("n", "<leader>gd", vim.lsp.buf.definition, opts)
        keyset("n", "<leader>rn", vim.lsp.buf.rename, opts)
        keyset("n", "<leader>fc", function()
            vim.lsp.buf.format({ async = true })
        end, opts)
        keyset("n", "<leader>xx", function() diagnostics.open_quickfixlist() end, opts)
    end,
})
