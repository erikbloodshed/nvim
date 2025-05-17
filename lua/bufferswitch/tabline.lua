-- BufferSwitcher: tabline display module
local M = {}

local utils = require("bufferswitch.utils")

-- Attempt to load nvim-web-devicons for NerdFont icons
local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

-- Format buffer name with NerdFont icon
function M.format_buffer_name(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return '[Invalid]'
    end

    local name = vim.fn.bufname(bufnr)
    local display_name = vim.fn.fnamemodify(name, ':t')
    local buf_type = vim.bo[bufnr].buftype

    -- Handle different buffer types
    if buf_type == 'help' then
        display_name = "[Help] " .. (display_name ~= '' and display_name or 'help')
    elseif display_name == '' then
        display_name = '[No Name]'
    end

    local ext = display_name:match('%.([^%.]+)$') or ''
    local icon = ''
    if has_devicons then
        icon = devicons.get_icon(display_name, ext, { default = true }) or ''
    end

    return (icon ~= '' and icon .. ' ' or '') .. display_name
end

-- Update the tabline with buffer names, handling abbreviation and width
function M.update_tabline_display(buffer_order)
    local current = vim.api.nvim_get_current_buf()
    local parts = {}
    local max_width = vim.o.columns
    local num_listed_buffers = #buffer_order
    local initial_max_tab_width = 15
    local min_width_per_tab = 5
    local separator_width = 1

    -- First pass: Calculate the desired width of each tab
    local tab_widths = {}
    local total_desired_width = 0

    for _, bufnr in ipairs(buffer_order) do
        local buf_label_full = M.format_buffer_name(bufnr)
        local desired_width = math.min(vim.fn.strwidth(buf_label_full), initial_max_tab_width) + 2 * 1 -- Minimal padding
        tab_widths[bufnr] = { full = buf_label_full, desired = desired_width, current_width = desired_width }
        total_desired_width = total_desired_width + desired_width
    end

    local available_width_for_labels = max_width - (num_listed_buffers - 1) * separator_width -
        num_listed_buffers * 2 * 1 -- Separators and padding

    -- Second pass: Generate tabline parts, abbreviating if needed
    for _, bufnr in ipairs(buffer_order) do
        local tab_info = tab_widths[bufnr]
        local buf_label = tab_info.full
        local display_width = tab_info.current_width

        if total_desired_width > available_width_for_labels then
            -- Abbreviate if total desired width exceeds available space
            local target_width_per_tab = math.floor(available_width_for_labels / num_listed_buffers)
            display_width = math.max(target_width_per_tab, min_width_per_tab)
            if vim.fn.strwidth(buf_label) > display_width then
                buf_label = string.sub(buf_label, 1, display_width - 1) .. "…"
                display_width = vim.fn.strwidth(buf_label)
            end
        elseif vim.fn.strwidth(buf_label) > initial_max_tab_width then
            buf_label = string.sub(buf_label, 1, initial_max_tab_width) .. "…"
            display_width = initial_max_tab_width
        end

        local label = string.format(' %-' .. display_width .. 's ', buf_label)
        if bufnr == current then
            table.insert(parts, '%#TabLineSel#' .. label)
        else
            table.insert(parts, '%#TabLine#' .. label)
        end
    end

    if #parts > 0 then
        vim.o.tabline = table.concat(parts, '%#TabLine#|') .. '%#TabLineFill#%='
    else
        vim.o.tabline = '%#TabLineFill#%='
    end
end

-- Debounced tabline update function
function M.debounced_update_tabline(buffer_order)
    utils.debounce(function()
        M.update_tabline_display(buffer_order)
    end)
end

-- Show the tabline and schedule it to hide after timeout
function M.manage_tabline(config, buffer_order)
    buffer_order = buffer_order or {}

    -- Don't show tabline in special buffers if configured that way
    if config.hide_in_special and utils.is_special_buffer(config) then
        if vim.o.showtabline == 2 then
            vim.o.showtabline = 0
        end
        return
    end

    -- Stop any existing timer
    if utils.cleanup_timer(utils.get_hide_timer()) then
        utils.set_hide_timer(nil)
    end

    -- Update and show the tabline
    vim.o.showtabline = 2
    M.update_tabline_display(buffer_order)

    -- Create a new timer
    local timer = vim.loop.new_timer()
    if timer then
        utils.set_hide_timer(timer)
        timer:start(config.hide_timeout, 0, vim.schedule_wrap(function()
            -- Only hide if still valid and not in a special buffer
            if vim.o.showtabline == 2 then
                vim.o.showtabline = 0
            end

            -- Clean up timer
            if utils.cleanup_timer(utils.get_hide_timer()) then
                utils.set_hide_timer(nil)
            end
        end))
    end
end

-- Hide the tabline
function M.hide_tabline()
    vim.o.showtabline = 0
    if utils.cleanup_timer(utils.get_hide_timer()) then
        utils.set_hide_timer(nil)
    end
end

return M
