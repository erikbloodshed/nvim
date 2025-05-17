return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
        local autopairs = require("nvim-autopairs")

        autopairs.setup()

        -- Autoclosing angle-brackets.
        local rule = require("nvim-autopairs.rule")
        local conds = require("nvim-autopairs.conds")
        autopairs.add_rule(rule("<", ">", {
            -- Avoid conflicts with nvim-ts-autotag.
            "-html",
            "-javascriptreact",
            "-typescriptreact",
        }):with_pair(conds.before_regex("%a+:?:?$", 3)):with_move(function(opts)
            return opts.char == ">"
        end))
    end,
}
