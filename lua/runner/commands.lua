-- Create functions for command generation
local M = {}

M.create = function(state)
    local x = {}

    -- Generate compile command
    x.cmd_compile = function()
        if state.command_cache.compile_cmd then
            return state.command_cache.compile_cmd
        end

        local cmd = vim.deepcopy(state.cmd_template)
        cmd.compiler = state.compiler

        cmd.arg = vim.deepcopy(state.response_file)
        cmd.arg[#cmd.arg + 1] = "-o"
        cmd.arg[#cmd.arg + 1] = state.filetype == "asm" and state.obj_file or state.exe_file
        cmd.arg[#cmd.arg + 1] = state.src_file

        state.command_cache.compile_cmd = cmd

        return cmd
    end

    -- Generate link command
    x.cmd_link = function()
        if state.command_cache.link_cmd then
            return state.command_cache.link_cmd
        end

        local cmd = vim.deepcopy(state.cmd_template)
        cmd.compiler = state.linker

        cmd.arg = vim.deepcopy(state.linker_flags)
        cmd.arg[#cmd.arg + 1] = "-o"
        cmd.arg[#cmd.arg + 1] = state.exe_file
        cmd.arg[#cmd.arg + 1] = state.obj_file

        return cmd
    end

    -- Generate assemble command
    x.cmd_assemble = function()
        if state.command_cache.assemble_cmd then
            return state.command_cache.assemble_cmd
        end

        local cmd = vim.deepcopy(state.cmd_template)
        cmd.compiler = state.compiler

        cmd.arg = vim.deepcopy(state.response_file)
        cmd.arg[#cmd.arg + 1] = "-c"
        cmd.arg[#cmd.arg + 1] = "-S"
        cmd.arg[#cmd.arg + 1] = "-o"
        cmd.arg[#cmd.arg + 1] = state.asm_file
        cmd.arg[#cmd.arg + 1] = state.src_file

        state.command_cache.assemble_cmd = cmd

        return cmd
    end

    return x
end

return M
