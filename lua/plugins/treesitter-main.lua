return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    branch = "main",
    build = function()
        local parsers = { "asm", "bash", "cpp", "fish", "rust", "toml" }
        require("nvim-treesitter").install(parsers)
        require("nvim-treesitter").update()
    end,
    opts = function()
        vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
                local lang = vim.treesitter.language.get_lang(args.match)
                if lang and vim.treesitter.language.add(lang) then
                    vim.treesitter.start()
                end
            end
        })
    end
}
