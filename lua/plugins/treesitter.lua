return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "VeryLazy",
    init = function(plugin)
        require("lazy.core.loader").add_to_rtp(plugin)
        require("nvim-treesitter.query_predicates")
    end,
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
    config = function (_, opts)
        require("nvim-treesitter.configs").setup(opts)
    end
}
