-- lua/runner.lua (Main plugin file)
local config_module = require('coderunner.config')
local executor = require('coderunner.executor')
local log = vim.notify

local M = {}

-- Default group for autocommands to ensure they can be cleared.
local AUGROUP_NAME = "RunnerFileTypeSetup"

--- Sets up the runner plugin with user-provided configuration.
-- @param user_config table|nil User configuration to override defaults.
function M.setup(user_config)
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
        local group = vim.api.nvim_create_augroup(AUGROUP_NAME, { clear = true })
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

--- Adds or updates a custom runner configuration for a given filetype.
-- @param filetype string The filetype (e.g., "go", "rust").
-- @param runner_cfg table The configuration for this runner.
function M.add_runner(filetype, runner_cfg)
    config_module.add_runner(filetype, runner_cfg)
    log(
    "Added/Updated runner for " ..
    filetype ..
    ". You might need to re-run M.setup() or restart Neovim for keymap changes to apply to new filetypes if the FileType event was already triggered.",
        vim.log.levels.INFO)
    -- To make new filetypes immediately active for autocommands, setup would need to be recalled
    -- or a more dynamic autocommand registration would be needed.
    -- For simplicity, if a new filetype is added, user might need to trigger FileType event again or call setup.
end

--- Runs the file in the current buffer based on its filetype.
-- Can be called manually.
function M.run()
    executor.run_current_file(vim.api.nvim_get_current_buf())
end

--- Retrieves the current merged configuration of the plugin.
-- @return table The current configuration.
function M.get_config()
    return config_module.get()
end

return M
