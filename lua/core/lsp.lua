local api = vim.api
local lsp = vim.lsp
local diagnostic = vim.diagnostic
local keyset = vim.keymap.set
local autocmd = api.nvim_create_autocmd

lsp.enable({ "basedpyright", "ruff", "clangd", "luals" })

autocmd("LspAttach", {
  callback = function(args)
    local icons = require("ui.icons")
    local x = diagnostic.severity

    diagnostic.config({
      virtual_text = false,
      severity_sort = true,
      float = { border = "rounded" },
      signs = {
        text = { [x.ERROR] = icons.error, [x.WARN] = icons.warn, [x.HINT] = icons.hint, [x.INFO] = icons.info },
      },
    })


    local opts = { buffer = args.buf }
    keyset("n", "<leader>ed", diagnostic.open_float, opts)
    keyset("n", "<leader>gi", lsp.buf.implementation, opts)
    keyset("n", "<leader>gd", lsp.buf.definition, opts)
    keyset("n", "<leader>fc", function() lsp.buf.format({ async = true }) end, opts)
  end,
})
