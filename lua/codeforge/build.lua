local M = {
    init = function(config)
        local handler = require("codeforge.handler")
        local utils = require("codeforge.utils")
        local api = vim.api
        local fn = vim.fn

        local src_file = api.nvim_buf_get_name(0)
        local exe_file = config.output_directory .. fn.expand("%:t:r")
        local asm_file = exe_file .. ".s"

        local data_path = utils.get_data_path(config.data_dir_name)
        local data_file = nil
        local cmd_args = nil
        local hash = { compile = nil, assemble = nil }

        local compile_args = utils.merged_list(config.compile_opts, { "-o", exe_file, src_file })
        local assemble_args = utils.merged_list(config.compile_opts, { "-c", "-S", "-o", asm_file, src_file })

        local compile_command = { compiler = config.compiler, arg = compile_args, timeout = 15000, kill_delay = 3000 }
        local assemble_command = { compiler = config.compiler, arg = assemble_args }

        local function compile()
            return handler.translate(hash, "compile", compile_command)
        end

        local function run()
            if compile() then
                handler.run(exe_file, cmd_args, data_file)
            end
        end

        local function show_assembly()
            if handler.translate(hash, "assemble", assemble_command) then
                utils.open(asm_file, utils.read_file(asm_file), "asm")
            end
        end

        local function add_data_file()
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

        local function remove_data_file()
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

        local function get_build_info()
            local lines = {
                "Filename          : " .. fn.fnamemodify(src_file, ':t'),
                "Filetype          : " .. api.nvim_get_option_value("filetype", { buf = 0 }),
                "Compiler          : " .. config.compiler,
                "Compile Flags     : " .. table.concat(config.compile_opts, " "),
                "Output Directory  : " .. config.output_directory,
                "Data Directory    : " .. (data_path or "Not Found"),
                "Data File In Use  : " .. (data_file and fn.fnamemodify(data_file, ':t') or "None"),
                "Command Arguments : " .. (cmd_args or "None"),
                "Date Modified     : " .. utils.get_date_modified(src_file),
            }

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

        local function set_cmd_args()
            vim.ui.input({ prompt = "Enter command-line arguments: ", default = cmd_args or "" },
                function(args)
                    if args ~= "" then
                        cmd_args = args
                    else
                        cmd_args = nil
                    end
                end)
        end

        return {
            compile = compile,
            run = run,
            show_assembly = show_assembly,
            add_data_file = add_data_file,
            remove_data_file = remove_data_file,
            get_build_info = get_build_info,
            set_cmd_args = set_cmd_args
        }
    end
}

return M
