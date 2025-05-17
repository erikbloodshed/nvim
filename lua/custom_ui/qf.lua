--[[
  custom_qf.lua - A custom quickfix formatter for Neovim
  This module improves the appearance of quickfix and location list windows by:
  1. Adding diagnostic signs (/󱈸//) with appropriate highlighting
  2. Highlighting file paths using the Directory highlight group
  3. Highlighting line/column numbers using the Number highlight group
  4. Highlighting diagnostic messages with the same highlight as their signs
  5. Supporting path truncation for long file paths
  6. Making annotations like "(fix available)" appear in italic
--]]

local M = {}

local signs = {
    error   = { text = "", hl = 'DiagnosticSignError' },
    warning = { text = "󱈸", hl = 'DiagnosticSignWarn' },
    info    = { text = "", hl = 'DiagnosticSignInfo' },
    hint    = { text = "", hl = 'DiagnosticSignHint' },
}

-- Create a unique namespace for our buffer highlights
local namespace = vim.api.nvim_create_namespace('custom_qf')
-- Configuration settings with defaults
local show_multiple_lines = false      -- Whether to show multi-line messages
local max_filename_length = 0          -- Maximum length for filenames (0 = no limit)
local filename_truncate_prefix = '...' -- Prefix to show when truncating

-- Pads a string with spaces to reach the desired width
-- @param string The string to pad
-- @param pad_to The total width to pad to
-- @return The padded string
local function pad_right(string, pad_to)
    local new = string

    if pad_to == 0 then
        return string
    end

    for _ = vim.fn.strwidth(string), pad_to do
        new = new .. ' '
    end

    return new
end

-- Truncates a file path if it exceeds the maximum length
-- @param path The file path to potentially truncate
-- @return The (possibly) truncated path
local function trim_path(path)
    -- Convert to relative path
    local fname = vim.fn.fnamemodify(path, ':p:.')
    local len = vim.fn.strchars(fname)

    -- Truncate if configured maximum length is exceeded
    if max_filename_length > 0 and len > max_filename_length then
        fname = filename_truncate_prefix
            .. vim.fn.strpart(fname, len - max_filename_length, max_filename_length, 1)
    end

    return fname
end

-- Gets either quickfix or location list items based on info
-- @param info The quickfix formatting info from Neovim
-- @return Table containing the list items and buffer number
local function list_items(info)
    if info.quickfix == 1 then
        return vim.fn.getqflist({ id = info.id, items = 1, qfbufnr = 1 })
    else
        return vim.fn.getloclist(info.winid, { id = info.id, items = 1, qfbufnr = 1 })
    end
end

-- Applies all collected highlights to the buffer using extmarks
-- @param bufnr The buffer to apply highlights to
-- @param highlights Table of highlight definitions to apply
local function apply_highlights(bufnr, highlights)
    -- Check if the buffer is still valid before proceeding
    -- This helps if the quickfix buffer is closed unexpectedly
    if not vim.api.nvim_buf_is_valid(bufnr) then
        -- print("Warning: Quickfix buffer invalidated before applying highlights")
        return -- Exit the function if the buffer is not valid
    end

    for _, hl in ipairs(highlights) do
        -- Add a check to ensure 'hl' is not nil and has required fields
        if hl == nil or type(hl) ~= 'table' or hl.line == nil or hl.col == nil or hl.end_col == nil or hl.group == nil then
            -- Optionally log a warning or skip this iteration
            -- print("Warning: Skipping invalid or incomplete highlight entry:", hl)
            goto continue -- Skip if hl is nil, not a table, or missing essential fields
        end

        -- Add validation for end_col and line existence
        local line_length = 0
        -- Safely get the line content to determine length
        local lines = vim.api.nvim_buf_get_lines(bufnr, hl.line, hl.line + 1, false)

        if #lines > 0 then
            line_length = lines[1]:len()
        else
            -- The line no longer exists or is out of bounds by the time
            -- apply_highlights is executed.
            -- print("Warning: Skipping highlight for non-existent line:", hl.line)
            goto continue -- Skip this highlight if the line is gone
        end

        local end_col = hl.end_col
        -- Validate end_col against line length and start column
        if end_col < hl.col or end_col > line_length then
            -- print("Warning: Invalid end_col value for highlight:", hl)
            goto continue -- Skip if end_col is invalid
        end

        -- All checks passed, apply the extmark
        vim.api.nvim_buf_set_extmark(
            bufnr,
            namespace,
            hl.line,
            hl.col,
            {
                end_col = end_col,
                hl_group = hl.group,
                priority = 100,
            }
        )
        ::continue::
    end
end

-- Main formatting function called by Neovim's quickfixtextfunc
-- @param info Table containing formatting information from Neovim
-- @return Table of formatted strings for each quickfix/location list item
function M.format(info)
    -- Get the list items and buffer number
    local list = list_items(info)
    local qf_bufnr = list.qfbufnr
    local raw_items = list.items
    local lines = {}
    local pad_to = 0 -- For aligning text across all lines

    -- Map single-letter type codes to our sign configurations
    local type_mapping = {
        E = signs.error,   -- Error
        W = signs.warning, -- Warning
        I = signs.info,    -- Information
        N = signs.hint,    -- Note/Hint
    }

    local items = {}
    local show_sign = false -- Will be set to true if any item has a valid type

    -- Clear existing highlights when creating a new list
    if info.start_idx == 1 then
        vim.api.nvim_buf_clear_namespace(qf_bufnr, namespace, 0, -1)
    end

    -- First pass: collect and process all items
    for i = info.start_idx, info.end_idx do
        local raw = raw_items[i]

        if raw then
            -- Create a processed item with all the information we need
            local item = {
                type = raw.type,   -- Diagnostic type (E/W/I/N)
                text = raw.text,   -- Message text
                location = '',     -- File path + line/col (to be built)
                path_size = 0,     -- Length of just the file path part
                line_col_size = 0, -- Length of just the line/col part
                index = i,         -- Original index for positioning
            }

            -- Check if this item has a valid diagnostic type
            if type_mapping[item.type] then
                show_sign = true
            end

            -- Add file path to location if available
            if raw.bufnr > 0 then
                item.location = trim_path(vim.fn.bufname(raw.bufnr))
                item.path_size = #item.location
            end

            -- Add line and column numbers to location if available
            if raw.lnum and raw.lnum > 0 then
                local lnum = raw.lnum

                -- Handle multi-line spans
                if raw.end_lnum and raw.end_lnum > 0 and raw.end_lnum ~= lnum then
                    lnum = lnum .. '-' .. raw.end_lnum
                end

                -- Append line number to location
                if #item.location > 0 then
                    item.location = item.location .. ' ' .. lnum
                else
                    item.location = tostring(lnum)
                end

                -- Add column information if available
                if raw.col and raw.col > 0 then
                    local col = raw.col

                    -- Handle multi-column spans
                    if raw.end_col and raw.end_col > 0 and raw.end_col ~= col then
                        col = col .. '-' .. raw.end_col
                    end

                    item.location = item.location .. ':' .. col
                end

                -- Calculate the size of just the line/col part
                item.line_col_size = #item.location - item.path_size
            end

            -- Track the maximum location width for alignment
            local size = vim.fn.strwidth(item.location)
            if size > pad_to then
                pad_to = size
            end

            table.insert(items, item)
        end
    end

    -- Collection for our highlight specifications
    local highlights = {}

    -- Second pass: format items and collect highlights
    for _, item in ipairs(items) do
        local line_idx = item.index - 1 -- 0-indexed for buffer operations

        -- Get just the first line of the message by default
        -- (Quickfix window doesn't handle newlines well)
        local text = vim.split(item.text, '\n')[1]
        local location = item.location

        -- Alternative: join multiple lines with spaces if enabled
        if show_multiple_lines then
            text = vim.fn.substitute(item.text, '\n\\s*', ' ', 'g')
        end

        -- Trim whitespace from the message text
        text = vim.fn.trim(text)

        -- Only pad the location if there's actually text to show
        if text ~= '' then
            location = pad_right(location, pad_to)
        end

        -- Get the sign configuration for this item type
        local sign_conf = type_mapping[item.type]
        local sign = ' ' -- Default to space if no type or unknown type
        local sign_hl = nil

        if sign_conf then
            sign = sign_conf.text
            sign_hl = sign_conf.hl
        end

        -- Build the complete line: sign + location + message
        local prefix = show_sign and sign .. ' ' or ''
        local line = prefix .. location .. text

        -- Workaround for empty lines (prevents Vim's default "|| " formatting)
        if line == '' then
            line = ' '
        end

        -- Add highlight for the sign if available
        if show_sign and sign_hl then
            table.insert(
                highlights,
                { group = sign_hl, line = line_idx, col = 0, end_col = #sign }
            )

            -- Highlight the message text with the same highlight group as the sign
            -- This is the key feature that makes messages match their signs
            if text ~= '' then
                local text_start = #prefix + #location
                table.insert(
                    highlights,
                    { group = sign_hl, line = line_idx, col = text_start, end_col = #line }
                )
            end
        end

        -- Highlight the file path with Directory highlight group
        if item.path_size > 0 then
            table.insert(highlights, {
                group = 'Directory',
                line = line_idx,
                col = #prefix,
                end_col = #prefix + item.path_size,
            })
        end

        -- Highlight line/column numbers with Number highlight group
        if item.line_col_size > 0 then
            local col_start = #prefix + item.path_size

            table.insert(highlights, {
                group = 'Number',
                line = line_idx,
                col = col_start,
                end_col = col_start + item.line_col_size,
            })
        end

        -- Check for and highlight phrases like "(fix available)" with italic
        local fix_annotation_start = text:find("%([^)]*fix[^)]*%)")

        if fix_annotation_start then
            local fix_annotation_end = text:find("%)", fix_annotation_start)
            if fix_annotation_end then
                local text_start = #prefix + #location
                table.insert(highlights, {
                    group = 'Comment', -- Comment group typically uses italic formatting
                    line = line_idx,
                    col = text_start + fix_annotation_start - 1,
                    end_col = text_start + fix_annotation_end,
                })
            end
        end

        -- Add the formatted line to our result list
        table.insert(lines, line)
    end

    -- Schedule highlights to be applied after the quickfix window is populated
    -- (immediate application won't work as the lines aren't in the buffer yet)
    vim.schedule(function()
        apply_highlights(qf_bufnr, highlights)
    end)

    -- Return formatted lines for Neovim to display
    return lines
end

-- Create a custom highlight group for annotations (if user wants custom styling)
local function create_highlight_groups()
    -- Check if our custom highlight group already exists
    local exists = pcall(function() return vim.api.nvim_get_hl(0, { name = 'QfAnnotation' }) end)

    if not exists then
        -- Create a custom highlight group for annotations that links to Comment
        -- The Comment highlight group typically uses italic formatting
        vim.api.nvim_set_hl(0, 'QfAnnotation', { link = 'Comment' })
    end
end

-- Initialize the module with user configuration
-- @param opts Table of configuration options:
--   - signs: Table of custom sign configurations
--   - show_multiple_lines: Boolean to enable multi-line messages
--   - max_filename_length: Number for max filename length (0 = no limit)
--   - filename_truncate_prefix: String prefix for truncated filenames
function M.setup(opts)
    opts = opts or {}

    -- Override default signs with user-provided ones
    if opts.signs then
        assert(type(opts.signs) == 'table', 'the "signs" option must be a table')
        signs = vim.tbl_deep_extend('force', signs, opts.signs)
    end

    -- Enable showing multiple lines joined with spaces
    if opts.show_multiple_lines then
        show_multiple_lines = true
    end

    -- Set maximum filename length for truncation
    if opts.max_filename_length then
        max_filename_length = opts.max_filename_length
        assert(
            type(max_filename_length) == 'number',
            'the "max_filename_length" option must be a number'
        )
    end

    -- Set the prefix to show when filenames are truncated
    if opts.filename_truncate_prefix then
        filename_truncate_prefix = opts.filename_truncate_prefix
        assert(
            type(filename_truncate_prefix) == 'string',
            'the "filename_truncate_prefix" option must be a string'
        )
    end

    -- Create our custom highlight groups
    create_highlight_groups()

    -- Register our format function with Neovim using Lua API
    vim.opt.quickfixtextfunc = "v:lua.require'custom_ui.qf'.format"
end

-- Example usage:
-- require('custom_qf').setup({
--   signs = {
--     error = { text = '✘', hl = 'DiagnosticSignError' },
--     warning = { text = '▲', hl = 'DiagnosticSignWarn' },
--   },
--   show_multiple_lines = true,
--   max_filename_length = 40,
--   filename_truncate_prefix = '...',
-- })

return M
