-- BufferSwitcher: configuration module
local M = {}

-- Create and validate configuration
function M.create(user_config)
    -- Default configuration
    local default_config = {
        hide_timeout = 1500,
        show_tabline = true,
        next_key = '<Right>',
        prev_key = '<Left>',
        orig_next_key = nil,                 -- Original key for next buffer
        orig_prev_key = nil,                 -- Original key for prev buffer
        hide_in_special = true,              -- Hide tabline in special buffers
        disable_in_special = true,           -- Disable keybindings in special buffers
        passthrough_keys_in_special = false, -- Pass through keys in special buffers
        special_buftypes = {                 -- Special buftypes to disable in
            "quickfix", "help", "nofile", "prompt", "terminal"
        },
        special_filetypes = { -- Special filetypes to disable in
            "qf", "help", "netrw", "fugitive", "NvimTree", "neo-tree",
            "nerdtree", "fern", "CHADTree", "Trouble", "dirvish"
        },
        special_bufname_patterns = { -- Special buffer name patterns
            "^term://", "^fugitive://", "^neo%-tree "
        },
        exclude_buftypes = { -- Buffer types to exclude from list
            "quickfix", "nofile", "help", "terminal", "prompt"
        },
        exclude_filetypes = { -- Filetypes to exclude from list
            "qf", "netrw", "Trouble", "fugitive"
        },
        periodic_cleanup = true, -- Enable periodic cleanup
        debug = false,           -- Enable debug logging
    }

    -- Merge user config
    if user_config then
        return vim.tbl_deep_extend('force', default_config, user_config)
    end

    return default_config
end

return M
