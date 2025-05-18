local M = {
    init = function(config)
        local handler = require("codeforge.handler")
        local utils = require("codeforge.utils")
        local api = vim.api
        local fn = vim.fn

        local filetype = api.nvim_get_option_value("filetype", { buf = 0 })
        local src_file = api.nvim_buf_get_name(0)
        local src_basename = fn.expand("%:t:r")
        local is_compiled = config.is_compiled
        local compiler = config.compiler
        local compile_opts = config.compile_opts
        local linker = config.linker
        local linker_flags = config.linker_flags
        local output_directory = config.output_directory
        local exe_file = output_directory .. src_basename
        local asm_file = exe_file .. ".s"
        local obj_file = exe_file .. ".o"
        local run_cmd = config.run_command
        local data_path = utils.get_data_path(config.data_dir_name)
        local data_file = nil
        local cmd_args = nil

        local hash_tbl = utils.prealloc(0, 3)
        hash_tbl.compile = nil
        hash_tbl.assemble = nil
        hash_tbl.link = nil

        local command_cache = utils.prealloc(0, 6)
        command_cache.compile_cmd = nil
        command_cache.compile_signature = nil
        command_cache.link_cmd = nil
        command_cache.link_signature = nil
        command_cache.assemble_cmd = nil
        command_cache.assemble_signature = nil

        local cmd = utils.prealloc(0, 4)
        cmd.compiler = nil
        cmd.arg = nil
        cmd.timeout = 15000
        cmd.kill_delay = 3000

        local function create_compile_signature()
            return table.concat({
                src_file,
                filetype,
                obj_file,
                exe_file,
                compiler,
                table.concat(compile_opts or {}, " ")
            }, "|")
        end

        local function create_link_signature()
            return table.concat({
                obj_file,
                exe_file,
                linker,
                table.concat(linker_flags or {}, " ")
            }, "|")
        end

        local function cmd_compile()
            local current_signature = create_compile_signature()

            if command_cache.compile_signature == current_signature and command_cache.compile_cmd then
                return command_cache.compile_cmd
            end

            cmd.compiler = compiler
            cmd.arg = utils.merged_list(compile_opts, { "-o", filetype == "asm" and obj_file or exe_file, src_file })
            command_cache.compile_cmd = cmd
            command_cache.compile_signature = current_signature

            return cmd
        end

        local function cmd_link()
            local current_signature = create_link_signature()

            if command_cache.link_signature == current_signature and command_cache.link_cmd then
                return command_cache.link_cmd
            end

            cmd.compiler = linker
            cmd.arg = utils.merged_list(linker_flags, { "-o", exe_file, obj_file })
            command_cache.link_cmd = cmd
            command_cache.link_signature = current_signature

            return cmd
        end

        local function clear_command_caches()
            command_cache.compile_cmd = nil
            command_cache.compile_signature = nil
            command_cache.link_cmd = nil
            command_cache.link_signature = nil
            command_cache.assemble_cmd = nil
            command_cache.assemble_signature = nil
        end

        local Actions = utils.prealloc(0, 7)

        Actions.compile = function()
            vim.cmd("silent! update")

            local diagnostic_count = #vim.diagnostic.count(0, { severity = { vim.diagnostic.severity.ERROR } })

            if diagnostic_count == 0 then
                if is_compiled then
                    local success = handler.translate(hash_tbl, "compile", cmd_compile())

                    if success and filetype == "asm" and linker then
                        return handler.translate(hash_tbl, "link", cmd_link())
                    end

                    return success
                else
                    return true
                end
            else
                require("diagnostics").open_quickfixlist()
                return false
            end
        end

        local function create_assemble_signature()
            return table.concat({
                src_file,
                asm_file,
                compiler,
                table.concat(compile_opts or {}, " ")
            }, "|")
        end

        local function cmd_assemble()
            local current_signature = create_assemble_signature()

            if command_cache.assemble_signature == current_signature and command_cache.assemble_cmd then
                return command_cache.assemble_cmd
            end

            local assemble_args = utils.merged_list(compile_opts, { "-c", "-S", "-o", asm_file, src_file })

            cmd.compiler = compiler
            cmd.arg = assemble_args

            command_cache.assemble_cmd = cmd
            command_cache.assemble_signature = current_signature

            return cmd
        end

        Actions.run = function()
            if Actions.compile() then
                if is_compiled then
                    handler.run(exe_file, cmd_args, data_file)
                else
                    handler.run(run_cmd .. " " .. src_file, cmd_args, data_file)
                end
            end
        end

        Actions.show_assembly = function()
            if filetype ~= "asm" and is_compiled then
                if handler.translate(hash_tbl, "assemble", cmd_assemble()) then
                    utils.open(asm_file, utils.read_file(asm_file), "asm")
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
            local flags = table.concat(compile_opts, " ")
            local lines = {
                "Filename          : " .. fn.fnamemodify(src_file, ':t'),
                "Filetype          : " .. filetype,
                "Compiler          : " .. compiler,
                "Compile Flags     : " .. (flags == "" and "None" or flags),
                "Output Directory  : " .. (output_directory == "" and "None" or output_directory),
                "Data Directory    : " .. (data_path or "Not Found"),
                "Data File In Use  : " .. (data_file and fn.fnamemodify(data_file, ':t') or "None"),
                "Command Arguments : " .. (cmd_args or "None"),
                "Date Modified     : " .. utils.get_date_modified(src_file),
            }

            if filetype == "asm" and linker then
                table.insert(lines, 3, "Linker            : " .. linker)
                table.insert(lines, 4, "Linker Flags      : " .. table.concat(linker_flags, " "))
            elseif not is_compiled then
                table.insert(lines, 3, "Run Command       : " .. run_cmd)
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

        local setup_cache_listeners = function()
            local group = api.nvim_create_augroup("CodeforgeCommandCacheInvalidation", { clear = true })

            api.nvim_create_autocmd("BufWritePost", {
                group = group,
                pattern = "*",
                callback = function()
                    local current_buf_name = api.nvim_buf_get_name(0)
                    if current_buf_name == src_file then
                        clear_command_caches()
                    end
                end,
            })
        end

        setup_cache_listeners()

        return Actions
    end
}

return M
