local api = vim.api
local keyset = vim.keymap.set
local autocmd = api.nvim_create_autocmd

autocmd({ "Filetype" }, {
  pattern = { "c", "cpp", "asm", "python", "lua" },
  callback = function(args)
    local ft = api.nvim_get_option_value("filetype", { buf = args.buf })

    if ft == "cpp" or ft == "c" then
      vim.opt_local.cinkeys:remove(":")
      vim.opt_local.cindent = true
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
          run_command = "python3.14"
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
    -- require("ui.statusline")

    keyset('n', "<Right>", function() require("bufferswitch").goto_next_buffer() end,
      { noremap = true, silent = true })
    keyset('n', "<Left>", function() require("bufferswitch").goto_prev_buffer() end,
      { noremap = true, silent = true })

    require('termswitch').setup({
      defaults = {
        width = 0.85,
        height = 0.85,
        border = 'rounded',
        open_in_file_dir = true,
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
        { name = 'ToggleTerm', terminal = 'shell' },
        { name = 'TogglePython', terminal = 'python', desc = "Toggle IPython REPL" },
      },

      keymaps = {
        { mode = 'n', lhs = '<leader>tt', terminal = 'shell', action = 'toggle', desc = 'Toggle shell' },
        { mode = 'n', lhs = '<leader>tp', terminal = 'python', action = 'toggle', desc = 'Toggle Python' },
        { mode = 't', lhs = '<leader>tt', terminal = 'shell', action = 'hide', desc = 'Hide shell' },
        { mode = 't', lhs = '<leader>tp', terminal = 'python', action = 'hide', desc = 'Hide Python' },
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
