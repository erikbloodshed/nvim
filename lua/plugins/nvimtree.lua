return {
  "nvim-tree/nvim-tree.lua",

  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  keys = {
    {
      '<leader>ef',
      function()
        require("nvim-tree.api").tree.toggle({ find_file = true, update_root = true })
      end
    },
    {
      '<C-,>',
      function()
        require("nvim-tree.api").tree.toggle({ path = "/home/xenyan/.config/nvim", find_file = true })
      end
    },
  },

  config = function()
    local nvimtree, icons = require("nvim-tree"), require("ui.icons")

    nvimtree.setup({
      hijack_netrw = true,
      reload_on_bufenter = true,

      actions = {
        open_file = {
          quit_on_open = true,
        },
      },

      renderer = {
        highlight_git = "all",
        icons = {
          git_placement = "right_align",
          modified_placement = "right_align"
        }
      },

      update_focused_file = {
        update_root = {
          enable = true,
        },
      },

      diagnostics = {
        enable = true,
        icons = {
          error = icons.error,
          warning = icons.warn,
          hint = icons.hint,
          info = icons.info,
        }
      },

      modified = {
        enable = true,
      },

      on_attach = function(bufnr)
        local api = require("nvim-tree.api")

        local opts = function(desc)
          return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        local maps = {
          ["."] = { api.tree.change_root_to_node, "CD" },
          ["<C-e>"] = { api.node.open.replace_tree_buffer, "Open: In Place" },
          ["<C-k>"] = { api.node.show_info_popup, "Info" },
          ["<C-r>"] = { api.fs.rename_sub, "Rename: Omit Filename" },
          ["<C-t>"] = { api.node.open.tab, "Open: New Tab" },
          ["<C-v>"] = { api.node.open.vertical, "Open: Vertical Split" },
          ["<C-x>"] = { api.node.open.horizontal, "Open: Horizontal Split" },
          ["<BS>"] = { api.node.navigate.parent_close, "Close Directory" },
          ["<CR>"] = { api.node.open.edit, "Open" },
          ["<Tab>"] = { api.node.open.preview, "Open Preview" },
          [">"] = { api.node.navigate.sibling.next, "Next Sibling" },
          ["<"] = { api.node.navigate.sibling.prev, "Previous Sibling" },
          ["]."] = { api.node.run.cmd, "Run Command" },
          ["-"] = { api.tree.change_root_to_parent, "Up" },
          ["a"] = { api.fs.create, "Create File Or Directory" },
          ["bd"] = { api.marks.bulk.delete, "Delete Bookmarked" },
          ["bt"] = { api.marks.bulk.trash, "Trash Bookmarked" },
          ["bmv"] = { api.marks.bulk.move, "Move Bookmarked" },
          ["B"] = { api.tree.toggle_no_buffer_filter, "Toggle Filter: No Buffer" },
          ["c"] = { api.fs.copy.node, "Copy" },
          ["C"] = { api.tree.toggle_git_clean_filter, "Toggle Filter: Git Clean" },
          ["[c"] = { api.node.navigate.git.prev, "Prev Git" },
          ["]c"] = { api.node.navigate.git.next, "Next Git" },
          ["d"] = { api.fs.trash, "Delete" },
          ["D"] = { api.fs.trash, "Trash" },
          ["E"] = { api.tree.expand_all, "Expand All" },
          ["e"] = { api.fs.rename_basename, "Rename: Basename" },
          ["]e"] = { api.node.navigate.diagnostics.next, "Next Diagnostic" },
          ["[e"] = { api.node.navigate.diagnostics.prev, "Prev Diagnostic" },
          ["F"] = { api.live_filter.clear, "Live Filter: Clear" },
          ["f"] = { api.live_filter.start, "Live Filter: Start" },
          ["g?"] = { api.tree.toggle_help, "Help" },
          ["gy"] = { api.fs.copy.absolute_path, "Copy Absolute Path" },
          ["ge"] = { api.fs.copy.basename, "Copy Basename" },
          ["H"] = { api.tree.toggle_hidden_filter, "Toggle Filter: Dotfiles" },
          ["I"] = { api.tree.toggle_gitignore_filter, "Toggle Filter: Git Ignore" },
          ["J"] = { api.node.navigate.sibling.last, "Last Sibling" },
          ["K"] = { api.node.navigate.sibling.first, "First Sibling" },
          ["L"] = { api.node.open.toggle_group_empty, "Toggle Group Empty" },
          ["M"] = { api.tree.toggle_no_bookmark_filter, "Toggle Filter: No Bookmark" },
          ["m"] = { api.marks.toggle, "Toggle Bookmark" },
          ["o"] = { api.node.open.edit, "Open" },
          ["O"] = { api.node.open.no_window_picker, "Open: No Window Picker" },
          ["p"] = { api.fs.paste, "Paste" },
          ["P"] = { api.node.navigate.parent, "Parent Directory" },
          ["q"] = { api.tree.close, "Close" },
          ["r"] = { api.fs.rename, "Rename" },
          ["R"] = { api.tree.reload, "Refresh" },
          ["s"] = { api.node.run.system, "Run System" },
          ["S"] = { api.tree.search_node, "Search" },
          ["u"] = { api.fs.rename_full, "Rename: Full Path" },
          ["U"] = { api.tree.toggle_custom_filter, "Toggle Filter: Hidden" },
          ["W"] = { api.tree.collapse_all, "Collapse All" },
          ["x"] = { api.fs.cut, "Cut" },
          ["y"] = { api.fs.copy.filename, "Copy Name" },
          ["Y"] = { api.fs.copy.relative_path, "Copy Relative Path" },
          ["<2-LeftMouse>"] = { api.node.open.edit, "Open" },
          ["<2-RightMouse>"] = { api.tree.change_root_to_node, "CD" }
        }

        local keyset = vim.keymap.set
        for k, m in pairs(maps) do
          keyset("n", k, m[1], opts(m[2]))
        end
      end,
    })

    local api, setlocal = vim.api, vim.opt_local
    local autocmd = api.nvim_create_autocmd
    local groupId = api.nvim_create_augroup("NvimTreeBuf", { clear = true })

    autocmd({ 'BufEnter', 'QuitPre' }, {
      group = groupId,
      nested = false,
      callback = function(e)
        local tree = require("nvim-tree.api").tree

        -- Nothing to do if tree is not opened
        if not tree.is_visible() then
          return
        end

        -- How many focusable windows do we have? (excluding e.g. incline status window)
        local winCount = 0
        for _, winId in ipairs(api.nvim_list_wins()) do
          if api.nvim_win_get_config(winId).focusable then
            winCount = winCount + 1
          end
        end

        -- We want to quit and only one window besides tree is left
        if e.event == 'QuitPre' and winCount == 2 then
          api.nvim_cmd({ cmd = 'qall' }, {})
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

    autocmd({ "WinEnter", "BufWinEnter" }, {
      callback = function(arg)
        local tree_api = require("nvim-tree.api")
        local hl = api.nvim_get_hl(0, { name = "Cursor", link = false })
        if tree_api.tree.is_tree_buf(arg.buf) then
          api.nvim_set_hl(0, "Cursor", { blend = 100, fg = hl.fg, bg = hl.bg })
          setlocal.guicursor:append("a:Cursor/lCursor")
        else
          api.nvim_set_hl(0, "Cursor", { blend = 0, fg = hl.fg, bg = hl.bg })
          setlocal.guicursor:remove("a:Cursor/lCursor")
        end
      end,
    })
  end,
}
