return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "VeryLazy",
    opts = {
        ensure_installed = {
        "bash",
        "cpp",
        "fish",
        "rust",
        "toml",
        },
        sync_install = false,
        indent = { enable = false },
        highlight = {
            enable = true,
        }
    },
}
