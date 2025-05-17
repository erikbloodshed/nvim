return {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--completion-style=bundled",
        "--function-arg-placeholders=0",
        "--header-insertion=never",
    },
    root_markers = { ".clangd" },
    filetypes = { "c", "cpp" },
    capabilities = {
        textDocument = {
            completion = {
                editsNearCursor = true,
            }
        },
        offsetEncoding = { "utf-8", "utf-16"},
    }
}
