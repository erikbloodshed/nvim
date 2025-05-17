local M = {
    init = function(config)
        local handler = require("codeforge.handler")
        local utils = require("codeforge.utils")
        local api = vim.api
        local fn = vim.fn

        local src_file = api.nvim_buf_get_name(0)
        local src_basename = fn.expand("%:t:r")
        local output_directory = config.output_directory
        local exe_file = output_directory .. src_basename
        local asm_file = exe_file .. ".s"
        local obj_file = exe_file .. ".o"

        local data_path = utils.get_data_path(config.data_dir_name)
        local data_file = nil
        local cmd_args = nil
        local hash = { compile = nil, assemble = nil, link = nil }

        local run_cmd = config.run_command

        local Actions = {}

        local function build_compile_command()
            local compile_args

            if config.is_compiled then
                if api.nvim_get_option_value("filetype", { buf = 0 }) == "asm" then
                    compile_args = utils.merged_list(config.compile_opts, { "-o", obj_file, src_file })
                else
                    compile_args = utils.merged_list(config.compile_opts, { "-o", exe_file, src_file })
                end
            else
                compile_args = utils.merged_list(config.compile_opts, { src_file })
            end

            return { compiler = config.compiler, arg = compile_args, timeout = 15000, kill_delay = 3000 }
        end

        local function build_link_command()
            return {
                compiler = config.linker,
                arg = utils.merged_list(config.linker_flags, { "-o", exe_file, obj_file }),
                timeout = 15000,
                kill_delay = 3000
            }
        end

        if config.is_compiled then
            Actions.compile = function()
                local success = handler.translate(hash, "compile", build_compile_command())

                if success and api.nvim_get_option_value("filetype", { buf = 0 }) == "asm" and config.linker then
                    return handler.translate(hash, "link", build_link_command())
                end

                return success
            end

            if api.nvim_get_option_value("filetype", { buf = 0 }) ~= "asm" then
                Actions.show_assembly = function()
                    local assemble_args = utils.merged_list(config.compile_opts, { "-c", "-S", "-o", asm_file, src_file })
                    local assemble_command = { compiler = config.compiler, arg = assemble_args }

                    if handler.translate(hash, "assemble", assemble_command) then
                        utils.open(asm_file, utils.read_file(asm_file), "asm")
                    end
                end
            end
        else
            Actions.compile = function()
                local check_command = build_compile_command()
                if api.nvim_get_option_value("filetype", { buf = 0 }) == "python" then
                    check_command.arg = utils.merged_list({ "--syntax-only" }, check_command.arg)
                end
                return handler.translate(hash, "compile", check_command)
            end
        end

        Actions.run = function()
            if Actions.compile() then
                if config.is_compiled then
                    handler.run(exe_file, cmd_args, data_file)
                else
                    handler.run(run_cmd .. " " .. src_file, cmd_args, data_file)
                end
            end
        end

        Actions.add_data_file = function()
            if data_path then
                local files = utils.scan_dir(data_path)

                if vim.tbl_isempty(files) then
                    vim.notify("No files found in data directory: " .. data_path, vim.log.levels.WARN)
                    return
                end

                vim.ui.select(files, {
                    prompt = "Current: " .. (data_file or "None"),
                    format_item = function(item)
                        return fn.fnamemodify(item, ':t')
                    end,
                }, function(choice)
                    if choice then
                        data_file = choice
                        vim.notify("Data file set to: " .. fn.fnamemodify(choice, ':t'), vim.log.levels.INFO)
                    end
                end)
            else
                vim.notify("'" .. config.data_dir_name .. "' directory not found.", vim.log.levels.ERROR)
            end
        end

        Actions.remove_data_file = function()
            if data_file then
                vim.ui.select({ "Yes", "No" }, {
                    prompt = "Remove data file (" .. fn.fnamemodify(data_file, ':t') .. ")?",
                }, function(choice)
                    if choice == "Yes" then
                        data_file = nil
                        vim.notify("Data file removed.", vim.log.levels.INFO)
                    end
                end)
                return
            end
            vim.notify("No data file is currently set.", vim.log.levels.WARN)
        end

        Actions.get_build_info = function()
            local filetype = api.nvim_get_option_value("filetype", { buf = 0 })
            local lines = {
                "Filename          : " .. fn.fnamemodify(src_file, ':t'),
                "Filetype          : " .. filetype,
                "Compiler          : " .. config.compiler,
                "Compile Flags     : " .. table.concat(config.compile_opts, " "),
                "Output Directory  : " .. config.output_directory,
                "Data Directory    : " .. (data_path or "Not Found"),
                "Data File In Use  : " .. (data_file and fn.fnamemodify(data_file, ':t') or "None"),
                "Command Arguments : " .. (cmd_args or "None"),
                "Date Modified     : " .. utils.get_date_modified(src_file),
            }

            -- Add language-specific info
            if filetype == "asm" and config.linker then
                table.insert(lines, 3, "Linker            : " .. config.linker)
                table.insert(lines, 4, "Linker Flags      : " .. table.concat(config.linker_flags, " "))
            elseif not config.is_compiled then
                table.insert(lines, 3, "Run Command       : " .. config.run_command)
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

        Actions.set_cmd_args = function()
            vim.ui.input({ prompt = "Enter command-line arguments: ", default = cmd_args or "" },
                function(args)
                    if args ~= "" then
                        cmd_args = args
                    else
                        cmd_args = nil
                    end
                end)
        end

        return Actions
    end
}

return M
