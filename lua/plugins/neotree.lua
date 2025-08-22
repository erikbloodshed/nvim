return {
  "nvim-neo-tree/neo-tree.nvim",

  keys = {
    {
      "<leader>ef",
      function()
        require("neo-tree.command").execute({
          toggle = true,
          reveal = true,
          reveal_force_cwd = true,
        })
      end,
    },

    {
      "<leader>ev",
      function()
        require("neo-tree.command").execute({
          dir = "/home/xenyan/.config/nvim",
          toggle = true,
          reveal = true,
        })
      end,
    },
  },

  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },

  config = function()
    local api = vim.api
    local opt = vim.opt

    local hl = api.nvim_get_hl(0, { name = "Cursor", link = false })
    opt.guicursor:append("a:Cursor/lCursor")
    local function hide_cursor()
      api.nvim_set_hl(0, "Cursor", { blend = 100, fg = hl.fg, bg = hl.bg })
    end

    local function show_cursor()
      api.nvim_set_hl(0, "Cursor", { blend = 0,fg = hl.fg, bg = hl.bg })
    end

    require("neo-tree").setup({
      source_selector = {
        winbar = false,
        statusline = false,
      },
      close_if_last_window = true,
      popup_border_style = "rounded",
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        filtered_items = {
          hide_by_pattern = { "*.out" },
        },
        use_libuv_file_watcher = false,
      },
      event_handlers = {
        {
          event = "neo_tree_buffer_enter",
          handler = hide_cursor
        },
        {
          event = "neo_tree_buffer_leave",
          handler = show_cursor,
        },
        {
          event = "file_opened",
          handler = function()
            require("neo-tree.command").execute({ action = "close" })
          end,
        },
        {
          event = "neo_tree_popup_input_ready",
          handler = function(args)
            show_cursor()
            vim.keymap.set("i", "<esc>", vim.cmd.stopinsert, {
              noremap = true, buffer = args.bufnr
            })
          end
        },
        {
          event = "neo_tree_popup_buffer_enter",
          handler = show_cursor,
        },
      },
    })
  end
}
