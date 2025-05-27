-- lua/runner/utils.lua
local M = {}

--- Replaces placeholders in a command template table with actual values.
-- Placeholders are in the format {key}.
-- @param cmd_template table A list of command arguments, some containing placeholders.
-- @param placeholders table A key-value map of placeholders and their replacements.
-- @return table A new list of command arguments with placeholders replaced.
function M.replace_placeholders(cmd_template, placeholders)
    local result = {}
    for _, arg_template in ipairs(cmd_template) do
        local replaced_arg = arg_template
        for key, value in pairs(placeholders) do
            -- Ensure value is a string to avoid errors with gsub if a placeholder value is nil
            replaced_arg = string.gsub(replaced_arg, "{" .. key .. "}", tostring(value or ""))
        end
        table.insert(result, replaced_arg)
    end
    return result
end

--- Gathers information about the current file.
-- @param bufnr integer The buffer number.
-- @param output_base_dir string The base directory for output files.
-- @return table|nil A table with file information, or nil if path is empty or output_base_dir not provided.
function M.get_file_info(bufnr, output_base_dir)
    local file_path = vim.api.nvim_buf_get_name(bufnr)

    if file_path == "" then
        vim.notify("Cannot get file info: Buffer has no associated file path.", vim.log.levels.ERROR)
        return nil
    end
    if not output_base_dir or output_base_dir == "" then
        vim.notify("Cannot get file info: Output directory is not defined.", vim.log.levels.ERROR)
        return nil
    end

    local file_name = vim.fn.fnamemodify(file_path, ":t")
    local basename = vim.fn.fnamemodify(file_path, ":t:r")
    local extension = vim.fn.fnamemodify(file_path, ":e")
    local output_path = output_base_dir .. "/" .. basename

    return {
        file = file_path,             -- Full path to the source file
        filename = file_name,         -- Name of the source file with extension
        basename = basename,          -- Name of the source file without extension
        extension = extension,        -- Extension of the source file
        output = output_path,         -- Full path for the output executable/file (without .o for asm)
        output_dir = output_base_dir, -- Directory for output files
    }
end

return M
