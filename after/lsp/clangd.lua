return {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--enable-config",
  },

  root_markers = { ".clangd" },

  filetypes = { "c", "cpp" },

  capabilities = {
    textDocument = {
      completion = {
        editsNearCursor = true,
      }
    },
  },
}
