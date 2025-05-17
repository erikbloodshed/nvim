return {
    "saghen/blink.cmp",
    event = { "InsertEnter" },
    build = "cargo +nightly build --release",

    opts = {
        completion = {
            accept = { auto_brackets = { enabled = false } },
            list = {
                selection = {
                    preselect = true,
                    auto_insert = false
                }
            },
            menu = {
                border = "rounded",
                scrollbar = false,
                draw = {
                    align_to = "label",
                    padding = 1,
                    gap = 2,
                    columns = { { "kind_icon" }, { "label" }, { "kind" } },
                },
            },
        },

        fuzzy = {
            sorts = { "exact", "score", "sort_text" }
        },

        keymap = {
            preset = "none",
            ["<Tab>"] = { "select_and_accept", "fallback" },
            ["<Up>"] = { "select_prev", "fallback" },
            ["<Down>"] = { "select_next", "fallback" },
            ["<C-p>"] = { "select_prev", "fallback" },
            ["<C-n>"] = { "select_next", "fallback" },
            ["<C-j>"] = { "snippet_forward", "fallback" },
            ["<C-k>"] = { "snippet_backward", "fallback" },
        },

        appearance = { use_nvim_cmp_as_default = false },
        sources = {
            default = { "lsp", "snippets", "path" },
            providers = {
                lsp = {
                    transform_items = function(_, items)
                        return vim.tbl_filter(function(item)
                            return not item.deprecated
                        end, items)
                    end,
                },
            },
        },
    },
}
