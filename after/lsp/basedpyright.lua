return {
  cmd = { "basedpyright-langserver", "--stdio", },
  filetypes = { "python" },
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "standard",
      },
      disableTaggedHints = true,
    },
  },
}
