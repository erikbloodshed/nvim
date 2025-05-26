local M = {}

M = {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = true,
    build = ":TSUpdate"
}

return M
