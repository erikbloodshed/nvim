-- lua/runner.lua (Main plugin file)
local M = {}

-- Default group for autocommands to ensure they can be cleared.

--- Sets up the runner plugin with user-provided configuration.
-- @param user_config table|nil User configuration to override defaults.
function M.setup(user_config)
    local config_module = require('coderunner.config')
    local executor = require('coderunner.executor')
    local log = vim.notify

    config_module.setup(user_config)
    local current_config = config_module.get()

    -- Create output directory if it doesn't exist
    if current_config.output_dir then
        if vim.fn.isdirectory(current_config.output_dir) == 0 then
            vim.fn.mkdir(current_config.output_dir, "p")
            log("Created output directory: " .. current_config.output_dir, vim.log.levels.INFO)
        end
    else
        log("Output directory not configured.", vim.log.levels.WARN)
    end

    -- Set up autocommands for supported filetypes
    local supported_filetypes = {}
    if current_config.runners then
        for ft, _ in pairs(current_config.runners) do
            table.insert(supported_filetypes, ft)
        end
    end

    if #supported_filetypes > 0 then
        local group = vim.api.nvim_create_augroup("RunnerFileTypeSetup", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
            pattern = supported_filetypes,
            group = group,
            callback = function(args)
                local current_config_for_keymap = config_module.get() -- Get fresh config
                local keymap = current_config_for_keymap.keymap or "<F5>"
                vim.keymap.set("n", keymap, function()
                    executor.run_current_file(args.buf)
                end, {
                    buffer = args.buf,
                    noremap = true,
                    silent = true,
                    desc = "Run current file (Runner)"
                })
            end,
            desc = "Setup runner keymap for supported filetypes"
        })
    else
        log("No runners configured, skipping autocommand setup.", vim.log.levels.INFO)
    end
end

return M
