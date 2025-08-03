local api = vim.api

local M = {}

function M.setup(terminal_manager)
    local default_terminal = terminal_manager.get_default_terminal()
    local python_terminal = terminal_manager.get_python_terminal()

    if not default_terminal or not python_terminal then
        vim.notify("TermSwitch: Default terminals not found, skipping keymap setup", vim.log.levels.WARN)
        return
    end

    local esc = api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true)

    local keymaps = {
        -- Default terminal keymaps
        {
            mode = 'n',
            lhs = '<leader>tt',
            rhs = function() default_terminal:toggle() end,
            desc = 'Toggle Terminal'
        },
        {
            mode = 't',
            lhs = '<leader>tt',
            rhs = function()
                api.nvim_feedkeys(esc, 't', false)
                vim.schedule(function() default_terminal:hide() end)
            end,
            desc = 'Hide Terminal (Terminal mode)'
        },

        -- Python terminal keymaps
        {
            mode = 'n',
            lhs = '<leader>tp',
            rhs = function() python_terminal:toggle() end,
            desc = 'Toggle Python'
        },
        {
            mode = 't',
            lhs = '<leader>tp',
            rhs = function()
                api.nvim_feedkeys(esc, 't', false)
                vim.schedule(function() python_terminal:hide() end)
            end,
            desc = 'Hide Python (Terminal mode)'
        },
    }

    for _, map in ipairs(keymaps) do
        vim.keymap.set(map.mode, map.lhs, map.rhs, {
            noremap = true,
            silent = true,
            desc = map.desc
        })
    end
end

return M
