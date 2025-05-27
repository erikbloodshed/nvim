return {
    "nvim-treesitter/nvim-treesitter",
    lazy = true,
    branch = "main",
    config = function()
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(details)
                if not pcall(vim.treesitter.start, details.buf) then
                    return
                end
            end
        })
    end
}
