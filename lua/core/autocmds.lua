local wo, api = vim.wo, vim.api
local keyset, autocmd = vim.keymap.set, api.nvim_create_autocmd

--- @diagnostic disable: assign-type-mismatch
autocmd({ "Filetype" }, {
  pattern = { "c", "cpp", "asm", "python", "lua" },
  callback = function(args)
    local ft = api.nvim_get_option_value("filetype", { buf = args.buf })

    if ft == "cpp" or ft == "c" then
      vim.opt_local.cinkeys:remove(":")
      vim.opt_local.cindent = true
    end

    if ft == "python" then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end

    require("runner").setup({
      filetype = {
        c = {
          response_file = ".compile_flags",
        },
        cpp = {
          response_file = ".compile_flags",
        },
        python = {
          run_command = "python3"
        }
      }
    })
  end,
})

autocmd({ "Filetype" }, {
  pattern = { "help", "qf" },
  callback = function(args)
    keyset("n", "q", function() vim.cmd.bdelete() end, { buffer = args.buf, silent = true, noremap = true })
  end,
})

autocmd({ "VimEnter" }, {
  once = true,
  callback = function()
    require("ui.input")
    require("ui.select")
    require("ui.statusline")

    keyset('n', "<Right>", function() require("bufferswitch").goto_next_buffer() end,
      { noremap = true, silent = true })
    keyset('n', "<Left>", function() require("bufferswitch").goto_prev_buffer() end,
      { noremap = true, silent = true })

    require('termswitch').setup({
      defaults = {
        width = 0.8,
        height = 0.8,
        border = 'rounded',
        open_in_file_dir = true,
        backdrop = {
          enabled = true,    -- Enable/disable backdrop
          opacity = 60,      -- Backdrop opacity (0-100)
          color = "#000000", -- Backdrop color
        }
      },

      terminals = {
        shell = {},
        python = {
          shell = 'python3.14', -- Or 'python'
          filetype = 'pyterm',
          auto_delete_on_close = true,
        },
      },

      commands = {
        { name = 'ToggleTerm',   terminal = 'shell' },
        { name = 'TogglePython', terminal = 'python', desc = "Toggle IPython REPL" },
      },

      keymaps = {
        { mode = 'n', lhs = '<leader>tt', terminal = 'shell',  action = 'toggle', desc = 'Toggle shell' },
        { mode = 'n', lhs = '<leader>tp', terminal = 'python', action = 'toggle', desc = 'Toggle Python' },
        { mode = 't', lhs = '<leader>tt', terminal = 'shell',  action = 'hide',   desc = 'Hide shell' },
        { mode = 't', lhs = '<leader>tp', terminal = 'python', action = 'hide',   desc = 'Hide Python' },
      },
    })
  end,
})

autocmd({ "TermOpen" }, {
  pattern = { "*" },
  callback = function()
    vim.cmd.startinsert()
  end,
})

local cl_group = api.nvim_create_augroup("CursorLineControl", { clear = true })

api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
  group = cl_group,
  callback = function()
    wo.cursorline = false
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = cl_group,
  callback = function()
    wo.cursorline = true
  end,
})
