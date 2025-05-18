-- Create functions for command generation
Command = {}

Command.create = function(state)
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

        cmd.arg = vim.deepcopy(state.compile_opts)
        cmd.arg[#cmd.arg + 1] = "-o"
        cmd.arg[#cmd.arg + 1] = state.filetype == "asm" and state.obj_file or state.exe_file
        cmd.arg[#cmd.arg + 1] = state.src_file

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

        cmd.arg = vim.deepcopy(state.linker_flags)
        cmd.arg[#cmd.arg + 1] = "-o"
        cmd.arg[#cmd.arg + 1] = state.exe_file
        cmd.arg[#cmd.arg + 1] = state.obj_file

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

        cmd.arg = vim.deepcopy(state.compile_opts)
        cmd.arg[#cmd.arg + 1] = "-c"
        cmd.arg[#cmd.arg + 1] = "-S"
        cmd.arg[#cmd.arg + 1] = "-o"
        cmd.arg[#cmd.arg + 1] = state.asm_file
        cmd.arg[#cmd.arg + 1] = state.src_file

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

return Command
