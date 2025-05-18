local M = {}

-- Create a state object to hold all build-related data
local function create_build_state(config)
    local api = vim.api
    local fn = vim.fn
    local utils = require("codeforge.utils")

    local state = {
        filetype = api.nvim_get_option_value("filetype", { buf = 0 }),
        src_file = api.nvim_buf_get_name(0),
        src_basename = fn.expand("%:t:r"),
        is_compiled = config.is_compiled,
        compiler = config.compiler,
        compile_opts = config.compile_opts or {},
        linker = config.linker,
        linker_flags = config.linker_flags or {},
        output_directory = config.output_directory or "",
        run_cmd = config.run_command,
        data_path = utils.get_data_path(config.data_dir_name),
        data_file = nil,
        cmd_args = nil,
        hash_tbl = utils.prealloc(0, 3),
        api = api,
        fn = fn,
        utils = utils
    }

    -- Initialize derived properties
    state.exe_file = state.output_directory .. state.src_basename
    state.asm_file = state.exe_file .. ".s"
    state.obj_file = state.exe_file .. ".o"

    -- Initialize hash table for the handler
    state.hash_tbl.compile = nil
    state.hash_tbl.assemble = nil
    state.hash_tbl.link = nil

    -- Command cache
    state.command_cache = {
        compile_cmd = nil,
        compile_signature = nil,
        link_cmd = nil,
        link_signature = nil,
        assemble_cmd = nil,
        assemble_signature = nil
    }

    -- Base command template
    state.cmd_template = utils.prealloc(0, 4)
    state.cmd_template.compiler = nil
    state.cmd_template.arg = nil
    state.cmd_template.timeout = 15000
    state.cmd_template.kill_delay = 3000

    return state
end

-- Create functions for command generation
local function create_command_generators(state)
    local utils = state.utils
    local commands = {}

    -- Create compile command signature
    commands.create_compile_signature = function()
        return table.concat({
            state.src_file,
            state.filetype,
            state.obj_file,
            state.exe_file,
            state.compiler,
            table.concat(state.compile_opts or {}, " ")
        }, "|")
    end

    -- Create link command signature
    commands.create_link_signature = function()
        return table.concat({
            state.obj_file,
            state.exe_file,
            state.linker,
            table.concat(state.linker_flags or {}, " ")
        }, "|")
    end

    -- Create assemble command signature
    commands.create_assemble_signature = function()
        return table.concat({
            state.src_file,
            state.asm_file,
            state.compiler,
            table.concat(state.compile_opts or {}, " ")
        }, "|")
    end

    -- Generate compile command
    commands.cmd_compile = function()
        local current_signature = commands.create_compile_signature()

        if state.command_cache.compile_signature == current_signature and state.command_cache.compile_cmd then
            return state.command_cache.compile_cmd
        end

        local cmd = vim.deepcopy(state.cmd_template)
        cmd.compiler = state.compiler
        cmd.arg = utils.merged_list(state.compile_opts, {
            "-o",
            state.filetype == "asm" and state.obj_file or state.exe_file,
            state.src_file
        })

        state.command_cache.compile_cmd = cmd
        state.command_cache.compile_signature = current_signature

        return cmd
    end

    -- Generate link command
    commands.cmd_link = function()
        local current_signature = commands.create_link_signature()

        if state.command_cache.link_signature == current_signature and state.command_cache.link_cmd then
            return state.command_cache.link_cmd
        end

        local cmd = vim.deepcopy(state.cmd_template)
        cmd.compiler = state.linker
        cmd.arg = utils.merged_list(state.linker_flags, { "-o", state.exe_file, state.obj_file })

        state.command_cache.link_cmd = cmd
        state.command_cache.link_signature = current_signature

        return cmd
    end

    -- Generate assemble command
    commands.cmd_assemble = function()
        local current_signature = commands.create_assemble_signature()

        if state.command_cache.assemble_signature == current_signature and state.command_cache.assemble_cmd then
            return state.command_cache.assemble_cmd
        end

        local cmd = vim.deepcopy(state.cmd_template)
        cmd.compiler = state.compiler
        cmd.arg = utils.merged_list(state.compile_opts, {
            "-c",
            "-S",
            "-o",
            state.asm_file,
            state.src_file
        })

        state.command_cache.assemble_cmd = cmd
        state.command_cache.assemble_signature = current_signature

        return cmd
    end

    -- Clear command caches
    commands.clear_caches = function()
        state.command_cache.compile_cmd = nil
        state.command_cache.compile_signature = nil
        state.command_cache.link_cmd = nil
        state.command_cache.link_signature = nil
        state.command_cache.assemble_cmd = nil
        state.command_cache.assemble_signature = nil
    end

    return commands
end

-- Create action functions that will be exposed to the user
local function create_actions(state, commands, handler)
    local api = state.api
    local fn = state.fn
    local utils = state.utils
    local actions = utils.prealloc(0, 7)

    -- Compile action
    actions.compile = function()
        vim.cmd("silent! update")

        local diagnostic_count = #vim.diagnostic.count(0, {
            severity = { vim.diagnostic.severity.ERROR }
        })

        if diagnostic_count > 0 then
            require("diagnostics").open_quickfixlist()
            vim.notify("Compilation aborted due to errors", vim.log.levels.ERROR)
            return false
        end

        if not state.is_compiled then
            return true
        end

        local success = handler.translate(state.hash_tbl, "compile", commands.cmd_compile())

        if not success then
            return false
        end

        if state.filetype == "asm" and state.linker then
            success = handler.translate(state.hash_tbl, "link", commands.cmd_link())
            if not success then
                return false
            end
        end

        return true
    end

    -- Run action
    actions.run = function()
        if actions.compile() then
            if state.is_compiled then
                handler.run(state.exe_file, state.cmd_args, state.data_file)
            else
                handler.run(state.run_cmd .. " " .. state.src_file, state.cmd_args, state.data_file)
            end
        end
    end

    -- Show assembly action
    actions.show_assembly = function()
        if state.filetype ~= "asm" and state.is_compiled then
            if handler.translate(state.hash_tbl, "assemble", commands.cmd_assemble()) then
                utils.open(state.asm_file, utils.read_file(state.asm_file), "asm")
            end
        end
    end

    -- Set command line arguments action
    actions.set_cmd_args = function()
        vim.ui.input({
            prompt = "Enter command-line arguments: ",
            default = state.cmd_args or ""
        }, function(args)
            if args ~= "" then
                state.cmd_args = args
                vim.notify("Command arguments set", vim.log.levels.INFO)
            else
                state.cmd_args = nil
                vim.notify("Command arguments cleared", vim.log.levels.INFO)
            end
        end)
    end

    -- Add data file action
    actions.add_data_file = function()
        if state.data_path then
            local files = utils.scan_dir(state.data_path)

            if vim.tbl_isempty(files) then
                vim.notify("No files found in data directory: " .. state.data_path, vim.log.levels.WARN)
                return
            end

            vim.ui.select(files, {
                prompt = "Current: " .. (state.data_file or "None"),
                format_item = function(item)
                    return fn.fnamemodify(item, ':t')
                end,
            }, function(choice)
                if choice then
                    state.data_file = choice
                    vim.notify("Data file set to: " .. fn.fnamemodify(choice, ':t'), vim.log.levels.INFO)
                end
            end)
        else
            vim.notify("Data directory not found", vim.log.levels.ERROR)
        end
    end

    -- Remove data file action
    actions.remove_data_file = function()
        if state.data_file then
            vim.ui.select({ "Yes", "No" }, {
                prompt = "Remove data file (" .. fn.fnamemodify(state.data_file, ':t') .. ")?",
            }, function(choice)
                if choice == "Yes" then
                    state.data_file = nil
                    vim.notify("Data file removed", vim.log.levels.INFO)
                end
            end)
        else
            vim.notify("No data file is currently set", vim.log.levels.WARN)
        end
    end

    -- Get build info action
    actions.get_build_info = function()
        local flags = table.concat(state.compile_opts, " ")
        local lines = {
            "Filename          : " .. fn.fnamemodify(state.src_file, ':t'),
            "Filetype          : " .. state.filetype,
            "Compiler          : " .. state.compiler,
            "Compile Flags     : " .. (flags == "" and "None" or flags),
            "Output Directory  : " .. (state.output_directory == "" and "None" or state.output_directory),
            "Data Directory    : " .. (state.data_path or "Not Found"),
            "Data File In Use  : " .. (state.data_file and fn.fnamemodify(state.data_file, ':t') or "None"),
            "Command Arguments : " .. (state.cmd_args or "None"),
            "Date Modified     : " .. utils.get_date_modified(state.src_file),
        }

        if state.filetype == "asm" and state.linker then
            table.insert(lines, 3, "Linker            : " .. state.linker)
            table.insert(lines, 4, "Linker Flags      : " .. table.concat(state.linker_flags, " "))
        elseif not state.is_compiled then
            table.insert(lines, 3, "Run Command       : " .. state.run_cmd)
        end

        local ns_id = api.nvim_create_namespace("build_info_highlight")
        local buf_id = utils.open("Build Info", lines, "text")

        for idx = 1, #lines do
            local line = lines[idx]
            local colon_pos = line:find(":")
            if colon_pos and colon_pos > 1 then
                api.nvim_buf_set_extmark(buf_id, ns_id, idx - 1, 0, {
                    end_col = colon_pos - 1,
                    hl_group = "Keyword"
                })
            end
        end
    end

    return actions
end

-- Setup event listeners for cache invalidation
local function setup_cache_listeners(state, commands)
    local api = state.api
    local group = api.nvim_create_augroup("CodeforgeCommandCacheInvalidation", { clear = true })

    api.nvim_create_autocmd("BufWritePost", {
        group = group,
        pattern = "*",
        callback = function()
            local current_buf_name = api.nvim_buf_get_name(0)
            if current_buf_name == state.src_file then
                commands.clear_caches()
            end
        end,
    })

    -- Add additional event listeners for other state changes
    -- For example, detecting changes to compiler settings, etc.
end

-- Validate the configuration
local function validate_config(config)
    assert(config, "Configuration is required")

    if config.is_compiled then
        assert(config.compiler, "Compiler must be specified for compiled languages")
        assert(config.output_directory, "Output directory must be specified")
    else
        assert(config.run_command, "Run command must be specified for interpreted languages")
    end

    -- Ensure output directory ends with a path separator
    if config.output_directory and #config.output_directory > 0 then
        local last_char = config.output_directory:sub(-1)
        if last_char ~= "/" and last_char ~= "\\" then
            config.output_directory = config.output_directory .. "/"
        end
    end

    return config
end

-- Main initialization function
M.init = function(config)
    config = validate_config(config)
    local handler = require("codeforge.handler")

    -- Create the state
    local state = create_build_state(config)

    -- Create command generators
    local commands = create_command_generators(state)

    -- Create action functions
    local actions = create_actions(state, commands, handler)

    -- Setup event listeners
    setup_cache_listeners(state, commands)

    -- Return the actions object
    return actions
end

return M
