return {
    "nvim-treesitter/nvim-treesitter",
    event = "VeryLazy",
    branch = "main",
    build = function()
        local parsers = { "asm", "bash", "cpp", "fish", "python", "rust", "toml" }
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
