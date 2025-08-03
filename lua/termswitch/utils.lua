local api = vim.api

local M = {}

-- Batch set options to reduce API calls
function M.set_win_options(win, options)
    for opt, val in pairs(options) do
        api.nvim_set_option_value(opt, val, { win = win })
    end
end

function M.set_buf_options(buf, options)
    for opt, val in pairs(options) do
        api.nvim_set_option_value(opt, val, { buf = buf })
    end
end

-- Cache UI dimensions to avoid repeated API calls
function M.get_ui_dimensions()
    local ui = api.nvim_list_uis()[1]
    return ui.width, ui.height
end

-- Create title with proper casing
function M.create_title(name)
    return ' ' .. name:gsub("^%l", string.upper) .. ' '
end

return M
