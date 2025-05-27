-- lua/runner/executor.lua
local config_module = require('coderunner.config')
local utils = require('coderunner.utils')
local job = require('coderunner.job')
local term = require('coderunner.term')
local log = vim.notify

local M = {}

--- Main function to process and run the file in the specified buffer.
-- @param bufnr integer|nil The buffer number to run. Defaults to current buffer.
function M.run_current_file(bufnr)
    local current_config = config_module.get()

    if not current_config or not next(current_config) then
        log("Runner plugin not configured or configuration is empty. Call setup({ ... }) first.", vim.log.levels.ERROR)
        return
    end

    if current_config.auto_save then
        vim.cmd.update()
    end

    local file_info = utils.get_file_info(bufnr, current_config.output_dir)
    if not file_info then
        log("Failed to get file information. Ensure the buffer has a name and output directory is set.",
            vim.log.levels.ERROR)
        return
    end

    local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
    if not filetype or filetype == "" then -- Fallback if FileType autocmd hasn't fired or ft is empty
        filetype = vim.bo[bufnr].filetype
    end

    if not filetype or filetype == "" then
        log("Could not determine filetype for buffer " .. bufnr .. ". Execution aborted.", vim.log.levels.WARN)
        return
    end

    local runner_settings = current_config.runners and current_config.runners[filetype]
    if not runner_settings then
        log("No runner configured for filetype: '" .. filetype .. "'.Execution aborted.", vim.log.levels.WARN)
        return
    end

    -- Prerequisite checks for specific filetypes (e.g., assembler and linker for 'asm')
    if filetype == "asm" then
        if runner_settings.compile and type(runner_settings.compile) == "table" and #runner_settings.compile > 0 then
            local assembler = runner_settings.compile[1]
            if vim.fn.executable(assembler) == 0 then
                log("Assembler '" .. assembler .. "' not found. Please install it or check PATH.", vim.log.levels.ERROR)
                return
            end
        end
        if runner_settings.needs_linking then
            if vim.fn.executable("ld") == 0 then -- Assuming 'ld' is the linker for asm if linking is needed
                log("Linker 'ld' not found. Please install binutils or check PATH.", vim.log.levels.ERROR)
                return
            end
        end
    end

    -- Start the compilation/linking process
    job.compile_and_link(runner_settings, file_info, function(success)
        if success then
            log("Compilation/linking phase successful for " .. file_info.filename .. ". Preparing to run.",
                vim.log.levels.INFO)
            local run_cmd_template
            if type(runner_settings.run) == "table" then
                run_cmd_template = runner_settings.run
            elseif type(runner_settings.run) == "string" then
                run_cmd_template = { runner_settings.run } -- Ensure it's a table for replace_placeholders
            else
                log(
                    "Invalid 'run' command format in runner config for filetype: " ..
                    filetype .. ". Must be a string or table.", vim.log.levels.ERROR)
                return
            end

            local run_cmd = utils.replace_placeholders(run_cmd_template, file_info)
            log("Executing command: " .. table.concat(run_cmd, " "), vim.log.levels.INFO)
            term.send_command(run_cmd, current_config.terminal_delay)
        else
            log("Execution aborted for " .. file_info.filename .. " due to errors in compilation or linking phase.",
                vim.log.levels.ERROR)
        end
    end)
end

return M
