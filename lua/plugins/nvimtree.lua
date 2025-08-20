local api = vim.api
local opt_local = vim.opt_local

local hl = api.nvim_get_hl(0, { name = "Cursor", link = false })

local function hide_cursor()
  api.nvim_set_hl(0, "Cursor", { blend = 100, fg = hl.fg, bg = hl.bg })
  opt_local.guicursor:append("a:Cursor/lCursor")
end

local function show_cursor()
  api.nvim_set_hl(0, "Cursor", { blend = 0, fg = hl.fg, bg = hl.bg })
  opt_local.guicursor:remove("a:Cursor/lCursor")
end

return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  config = function()
    require("nvim-tree").setup({
      hijack_cursor = true,
      reload_on_bufenter = true,
      update_focused_file = {
        update_root = {
          enable = true,
        },
      },
      diagnostics = {
        enable = true,
        icons = {
          error = "", warning = "󱈸", hint = "", info = "",
        }
      },
      modified = {
        enable = true,
      }
    })

    vim.api.nvim_create_autocmd({ 'BufEnter', 'QuitPre' }, {
      nested = false,
      callback = function(e)
        local tree = require('nvim-tree.api').tree

        -- Nothing to do if tree is not opened
        if not tree.is_visible() then
          return
        end

        -- How many focusable windows do we have? (excluding e.g. incline status window)
        local winCount = 0
        for _, winId in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_config(winId).focusable then
            winCount = winCount + 1
          end
        end

        -- We want to quit and only one window besides tree is left
        if e.event == 'QuitPre' and winCount == 2 then
          vim.api.nvim_cmd({ cmd = 'qall' }, {})
        end

        -- :bd was probably issued an only tree window is left
        -- Behave as if tree was closed (see `:h :bd`)
        if e.event == 'BufEnter' and winCount == 1 then
          -- Required to avoid "Vim:E444: Cannot close last window"
          vim.defer_fn(function()
            -- close nvim-tree: will go to the last buffer used before closing
            tree.toggle({ find_file = true, focus = true })
            -- re-open nivm-tree
            tree.toggle({ find_file = true, focus = false })
          end, 10)
        end
      end
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
      pattern = "NvimTree*",
      callback = hide_cursor
    })

    vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed" }, {
      pattern = "NvimTree*",
      callback = show_cursor
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
