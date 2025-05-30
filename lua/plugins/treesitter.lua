return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "VeryLazy",
    opts = {
        ensure_installed = {
            "asm",
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
    config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)
    end
}
