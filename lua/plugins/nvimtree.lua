return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  config = function()
    require("nvim-tree").setup({
      hijack_cursor = true,
    })
  end,

  keys = {
    {
      '<leader>ef',
      function()
        require("nvim-tree.api").tree.toggle()
      end
    },
  },
}
