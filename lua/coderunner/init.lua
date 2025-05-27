-- lua/runner.lua
-- A flexible runner plugin for Neovim that supports multiple programming languages

local M = {}

-- Default configuration
local default_config = {
    -- Key mapping for running files
    keymap = "<F5>",
    -- Output directory for compiled files
    output_dir = "/tmp",
    -- Terminal delay (ms) before sending command
    terminal_delay = 75,
    -- Auto-save before running
    auto_save = true,
    -- Custom runners for different filetypes
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
        -- Assembly language support
        asm = {
            compile = { "nasm", "-f", "elf64", "-o", "{output}.o", "{file}" },
            link = { "ld", "-o", "{output}", "{output}.o" },
            run = "{output}",
            needs_compilation = true,
            needs_linking = true,
        }
    }
}

-- Plugin configuration
local config = {}

-- Utility function to replace placeholders in command
local function replace_placeholders(cmd, placeholders)
    local result = {}
    for _, arg in ipairs(cmd) do
        local replaced_arg = arg
        for key, value in pairs(placeholders) do
            replaced_arg = string.gsub(replaced_arg, "{" .. key .. "}", value)
        end
        table.insert(result, replaced_arg)
    end
    return result
end

-- Get file information
local function get_file_info(bufnr)
    local file_path = vim.api.nvim_buf_get_name(bufnr)
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    local basename = vim.fn.fnamemodify(file_path, ":t:r")
    local extension = vim.fn.fnamemodify(file_path, ":e")
    local output_path = config.output_dir .. "/" .. basename

    return {
        file = file_path,
        filename = file_name,
        basename = basename,
        extension = extension,
        output = output_path,
        output_dir = config.output_dir,
    }
end

-- Send command to terminal
local function send_to_terminal(cmd_table)
    vim.cmd.terminal()
    vim.defer_fn(function()
        local bufnr = vim.api.nvim_get_current_buf()
        local term_id = vim.b[bufnr].terminal_job_id
        if term_id then
            local cmd_str = table.concat(cmd_table, " ")
            vim.api.nvim_chan_send(term_id, cmd_str .. "\n")
        else
            vim.notify("Could not get terminal job ID to send command.", vim.log.levels.WARN)
        end
    end, config.terminal_delay)
end

-- Link object files (for assembly and other languages that need separate linking)
local function link_file(runner, file_info, callback)
    if not runner.needs_linking then
        callback(true)
        return
    end

    local link_cmd = replace_placeholders(runner.link, file_info)

    vim.system(link_cmd, { text = true }, function(obj)
        vim.schedule(function()
            if obj.code == 0 then
                vim.notify("Linking successful!", vim.log.levels.INFO)
                callback(true)
            else
                local error_msg = "Linking failed!"
                if obj.stderr and obj.stderr ~= "" then
                    error_msg = error_msg .. "\n" .. obj.stderr
                end
                vim.notify(error_msg, vim.log.levels.ERROR)
                callback(false)
            end
        end)
    end)
end

-- Compile file if needed
local function compile_file(runner, file_info, callback)
    if not runner.needs_compilation then
        callback(true)
        return
    end

    local compile_cmd = replace_placeholders(runner.compile, file_info)

    vim.system(compile_cmd, { text = true }, function(obj)
        vim.schedule(function()
            if obj.code == 0 then
                vim.notify("Compilation successful!", vim.log.levels.INFO)
                -- If linking is needed, do it next
                if runner.needs_linking then
                    link_file(runner, file_info, callback)
                else
                    callback(true)
                end
            else
                local error_msg = "Compilation failed!"
                if obj.stderr and obj.stderr ~= "" then
                    error_msg = error_msg .. "\n" .. obj.stderr
                end
                vim.notify(error_msg, vim.log.levels.ERROR)
                callback(false)
            end
        end)
    end)
end

-- Main run function
local function run_file(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    -- Auto-save if enabled
    if config.auto_save then
        vim.cmd.update()
    end

    local file_info = get_file_info(bufnr)
    local filetype = vim.api.nvim_get_option_value("filetype", { buf = 0 })

    -- Check if we have a runner for this filetype
    local runner = config.runners[filetype]
    if not runner then
        vim.notify("No runner configured for filetype: " .. filetype, vim.log.levels.WARN)
        return
    end

    -- Check if file exists and is not empty
    if file_info.file == "" then
        vim.notify("Buffer has no associated file", vim.log.levels.ERROR)
        return
    end

    -- For assembly files, check if required tools are available
    if filetype == "asm" then
        local assembler = runner.compile[1]
        if vim.fn.executable(assembler) == 0 then
            vim.notify("Assembler '" .. assembler .. "' not found. Please install it first.", vim.log.levels.ERROR)
            return
        end
        if vim.fn.executable("ld") == 0 then
            vim.notify("Linker 'ld' not found. Please install binutils.", vim.log.levels.ERROR)
            return
        end
    end

    -- Compile if needed, then run
    compile_file(runner, file_info, function(success)
        if success then
            local run_cmd
            if type(runner.run) == "table" then
                run_cmd = replace_placeholders(runner.run, file_info)
            else
                run_cmd = { replace_placeholders({ runner.run }, file_info)[1] }
            end
            send_to_terminal(run_cmd)
        end
    end)
end

-- Setup function
function M.setup(user_config)
    -- Merge user config with defaults
    config = vim.tbl_deep_extend("force", default_config, user_config or {})

    -- Create output directory if it doesn't exist
    vim.fn.mkdir(config.output_dir, "p")

    -- Set up autocommands for supported filetypes
    local supported_filetypes = {}
    for ft, _ in pairs(config.runners) do
        table.insert(supported_filetypes, ft)
    end

    vim.api.nvim_create_autocmd("FileType", {
        pattern = supported_filetypes,
        callback = function(args)
            vim.keymap.set("n", config.keymap, function()
                run_file(args.buf)
            end, {
                buffer = args.buf,
                noremap = true,
                silent = true,
                desc = "Run current file"
            })
        end
    })
end

-- Add a custom runner
function M.add_runner(filetype, runner_config)
    config.runners[filetype] = runner_config
end

-- Run file manually (can be called from anywhere)
function M.run()
    run_file()
end

-- Get current configuration
function M.get_config()
    return config
end

return M
