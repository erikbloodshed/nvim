local M = {}

M.VALID_BORDERS = {
    none = true,
    single = true,
    double = true,
    rounded = true,
    solid = true,
    shadow = true
}

M.DEFAULT_CONFIG = {
    width = 0.8,
    height = 0.8,
    border = 'rounded',
    shell = nil,
    filetype = 'terminal',
    auto_delete_on_close = false,
}

function M.validate_config(cfg)
    local validated = vim.deepcopy(cfg)

    if validated.width and (validated.width <= 0 or validated.width > 1) then
        vim.notify("TermSwitch: 'width' must be between 0 and 1. Using default.", vim.log.levels.WARN)
        validated.width = M.DEFAULT_CONFIG.width
    end

    if validated.height and (validated.height <= 0 or validated.height > 1) then
        vim.notify("TermSwitch: 'height' must be between 0 and 1. Using default.", vim.log.levels.WARN)
        validated.height = M.DEFAULT_CONFIG.height
    end

    if validated.border and not M.VALID_BORDERS[validated.border] then
        vim.notify(string.format("TermSwitch: Invalid 'border' style '%s'. Using 'rounded'.", validated.border),
            vim.log.levels.WARN)
        validated.border = M.DEFAULT_CONFIG.border
    end

    return validated
end

return M
