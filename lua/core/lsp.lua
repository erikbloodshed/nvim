local api, lsp = vim.api, vim.lsp
local diagnostic, keyset, autocmd = vim.diagnostic, vim.keymap.set, api.nvim_create_autocmd

vim.lsp.config("*", {
  capabilities = {
    general = {
      positionEncodings = { "utf-16" },
    },
    textDocument = {
      onTypeFormatting = {
        dynamicRegistration = false,
      }
    }
  },
})

lsp.enable({ "basedpyright", "ruff", "clangd", "luals" })

autocmd("LspAttach", {
  callback = function(args)
    require("ui.qf")
    local client_id = args.data.client_id
    local client = assert(vim.lsp.get_client_by_id(client_id))
    if client.name == "ruff" then
      vim.lsp.on_type_formatting.enable(true, { client_id = client_id })
    end
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
