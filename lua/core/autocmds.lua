local wo, api = vim.wo, vim.api
local keyset, autocmd = vim.keymap.set, api.nvim_create_autocmd

--- @diagnostic disable-next-line: assign-type-mismatch
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

    require("xrun").setup({
      filetype = {
        c = {
          response_file = ".compile_flags",
        },
        cpp = {
          response_file = ".compile_flags",
        },
        python = {
          compiler = "python3.14"
        }
      }
    })
  end,
})

--- @diagnostic disable-next-line: assign-type-mismatch
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

    keyset('n', "<Right>", function() require("bufswitch").goto_next_buffer() end,
      { noremap = true, silent = true })
    keyset('n', "<Left>", function() require("bufswitch").goto_prev_buffer() end,
      { noremap = true, silent = true })
    keyset('n', "<C-t>", function() require("bufswitch").alt_tab_buffer() end,
      { noremap = true, silent = true })

    require('term').setup({
      defaults = {
        width = 0.8,
        height = 0.8,
        border = 'rounded',
        open_in_file_dir = true,
        open = true,
      },

      terminals = {
        shell = {},
        python = {
          shell = 'python3.14',
          filetype = 'nofile',
          auto_delete_on_close = true,
        },
      },

      commands = {
        { name = 'ToggleTerm', terminal = 'shell' },
        { name = 'TogglePython', terminal = 'python', desc = "Toggle IPython REPL" },
      },

      keymaps = {
        { mode = { 'n', 't' }, lhs = '<leader>tt', terminal = 'shell', action = 'toggle', desc = 'Toggle shell' },
        { mode = { 'n', 't' }, lhs = '<leader>tp', terminal = 'python', action = 'toggle', desc = 'Toggle Python' },
      },
    })
  end,
})

local cl_group = api.nvim_create_augroup("CursorLineControl", { clear = true })

api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
  group = cl_group,
  callback = function()
    wo.cursorline = false
  end,
})

api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = cl_group,
  callback = function()
    wo.cursorline = true
  end,
})
