-- lua/runner/config.lua
local M = {}

M.default_config = {
    keymap = "<F5>",
    output_dir = vim.fn.stdpath("cache") .. "/runner_output", -- Changed default to be within Neovim's cache
    terminal_delay = 75,
    auto_save = true,
    runners = {
        cpp = {
            compile = { "g++", "-std=c++17", "-o", "{output}", "{file}" },
            run = "{output}",
            needs_compilation = true,
        },
        c = {
            compile = { "gcc", "-std=c23", "-o", "{output}", "{file}" },
            run = "{output}",
            needs_compilation = true,
        },
        python = {
            run = { "python3", "{file}" },
            needs_compilation = false,
        },
        lua = {
            run = { "lua", "{file}" },
            needs_compilation = false,
        },
        asm = {
            compile = { "nasm", "-f", "elf64", "-o", "{output}.o", "{file}" },
            link = { "ld", "-o", "{output}", "{output}.o" },
            run = "{output}",
            needs_compilation = true,
            needs_linking = true,
        }
    }
}

M.options = {} -- This will hold the merged configuration

--- Merges user configuration with defaults.
-- @param user_config table|nil User-provided configuration.
function M.setup(user_config)
    -- Deepcopy default_config to prevent modification of the defaults table
    local defaults_copy = vim.deepcopy(M.default_config)
    M.options = vim.tbl_deep_extend("force", defaults_copy, user_config or {})
end

--- Gets the current configuration.
-- @return table The merged configuration options.
function M.get()
    if not next(M.options) then -- Check if M.options is empty
        -- Initialize with defaults if setup hasn't been called
        -- This can happen if get_config() is called before setup()
        M.setup({})
        vim.notify("Runner config not explicitly set up, using defaults. Call setup() for custom config.",
            vim.log.levels.WARN)
    end
    return M.options
end

--- Adds or updates a runner configuration for a specific filetype.
-- @param filetype string The filetype identifier (e.g., "python").
-- @param runner_config table The configuration for the runner.
function M.add_runner(filetype, runner_config)
    if not M.options.runners then
        M.options.runners = {}
    end
    M.options.runners[filetype] = runner_config
end

return M
