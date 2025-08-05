-- termswitch/keymaps.lua
local api = vim.api

local M = {}

--- Sets up user-defined keymaps.
---@param terminal_manager table The terminal manager module.
---@param user_keymaps table A list of keymap configurations from the user.
function M.setup(terminal_manager, user_keymaps)
    if not user_keymaps or type(user_keymaps) ~= 'table' then
        return
    end

    local esc = api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true)

    for _, map_config in ipairs(user_keymaps) do
        -- Validate the keymap configuration entry
        if not (map_config.lhs and map_config.terminal and map_config.action) then
            vim.notify("TermSwitch: Invalid keymap config. Requires 'lhs', 'terminal', and 'action'.",
                vim.log.levels.WARN)
            goto continue
        end

        local terminal = terminal_manager.get_terminal(map_config.terminal)
        if not terminal then
            vim.notify(
            string.format("TermSwitch: Terminal '%s' not found for keymap '%s'.", map_config.terminal, map_config.lhs),
                vim.log.levels.WARN)
            goto continue
        end

        local rhs
        if map_config.action == 'toggle' then
            rhs = function() terminal:toggle() end
        elseif map_config.action == 'hide' then
            rhs = function()
                -- Special handling for hiding from within terminal mode
                if map_config.mode == 't' then
                    api.nvim_feedkeys(esc, 't', false)
                    vim.schedule(function() terminal:hide() end)
                else
                    terminal:hide()
                end
            end
        elseif map_config.action == 'open' then
            rhs = function() terminal:open() end
        elseif map_config.action == 'focus' then
            rhs = function() terminal:focus() end
        else
            vim.notify(
            string.format("TermSwitch: Invalid keymap action '%s' for '%s'.", map_config.action, map_config.lhs),
                vim.log.levels.WARN)
            goto continue
        end

        vim.keymap.set(map_config.mode or 'n', map_config.lhs, rhs, {
            noremap = true,
            silent = true,
            desc = map_config.desc or
            string.format("%s '%s' terminal", map_config.action:gsub("^%l", string.upper), map_config.terminal)
        })

        ::continue::
    end
end

return M
