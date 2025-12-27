local parsers = { "asm", "bash", "cpp", "fish", "python", "rust", "toml" }

return {
  "nvim-treesitter/nvim-treesitter",
  event = "VeryLazy",
  branch = "main",

  build = function()
    require("nvim-treesitter").install(parsers)
    require("nvim-treesitter").update()
  end,

  config = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = parsers,
      callback = function() vim.treesitter.start() end
      -- callback = function(args)
      --   local lang = vim.treesitter.language.get_lang(args.match)
      --   if lang and vim.treesitter.language.add(lang) then
      --     vim.treesitter.start()
      --   end
      -- end
    })
  end
}
