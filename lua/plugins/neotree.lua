local api = vim.api
local opt = vim.opt

local hl = api.nvim_get_hl(0, { name = "Cursor", link = false })

local function hide_cursor()
    api.nvim_set_hl(0, "Cursor", { blend = 100, fg = hl.fg, bg = hl.bg })
    opt.guicursor:append("a:Cursor/lCursor")
end

local function show_cursor()
    api.nvim_set_hl(0, "Cursor", { blend = 0, fg = hl.fg, bg = hl.bg })
    opt.guicursor:remove("a:Cursor/lCursor")
end

return {
    "nvim-neo-tree/neo-tree.nvim",

    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },

    opts = {
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
                handler = function() hide_cursor() end,
            },
            {
                event = "neo_tree_buffer_leave",
                handler = function() show_cursor() end,
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
                    vim.keymap.set("i", "<esc>", vim.cmd.stopinsert, { buffer = args.bufnr })
                end,
            },
            {
                event = "neo_tree_popup_buffer_enter",
                handler = function(args)
                    show_cursor()
                    vim.keymap.set("i", "<esc>", vim.cmd.stopinsert, { buffer = args.bufnr })
                end,
            },
        },
    },

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
    },
}
