local api, lsp = vim.api, vim.lsp
local diagnostic, keyset, autocmd = vim.diagnostic, vim.keymap.set, api.nvim_create_autocmd

lsp.enable({ "basedpyright", "clangd", "luals" })

autocmd("LspAttach", {
  callback = function(args)
    require("ui.qf").setup({ show_multiple_lines = false, max_filename_length = 30, })

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
