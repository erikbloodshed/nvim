local api = vim.api
local keyset = vim.keymap.set
local autocmd = api.nvim_create_autocmd
local lsp = vim.lsp

lsp.enable({ "basedpyright", "clangd", "luals" })

autocmd("LspAttach", {
    callback = function(args)
        local x = vim.diagnostic.severity

        vim.diagnostic.config({
            virtual_text = false,
            severity_sort = true,
            float = { border = "rounded" },
            signs = {
                text = { [x.ERROR] = "", [x.WARN] = "󱈸", [x.HINT] = "", [x.INFO] = "", },
            },
        })


        local opts = { buffer = args.buf }
        keyset("n", "<leader>ed", vim.diagnostic.open_float, opts)
        keyset("n", "<leader>gi", lsp.buf.implementation, opts)
        keyset("n", "<leader>gd", lsp.buf.definition, opts)
        keyset("n", "<leader>rn", lsp.buf.rename, opts)
        keyset("n", "<leader>ca", lsp.buf.code_action, opts)
        keyset("n", "<leader>fc", function()
            vim.lsp.buf.format({ async = true })
        end, opts)
    end,
})
