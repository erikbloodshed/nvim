-- In commands.lua
local M = {}

-- Factory that creates appropriate commands based on language types
M.create = function(state)
  local LANG_TYPES = require("runner.config").LANGUAGE_TYPES
  local language_types = state.language_types or {}
  local commands = {}

  -- Helper to check if language belongs to a type
  local has_type = function(type)
    for _, lang_type in ipairs(language_types) do
      if lang_type == type then
        return true
      end
    end
    return false
  end

  -- Add commands based on language type
  if has_type(LANG_TYPES.COMPILED) then
    commands.compile = function()
      if state.command_cache.compile_cmd then
        return state.command_cache.compile_cmd
      end

      local cmd = vim.deepcopy(state.cmd_template)
      cmd.compiler = state.compiler

      cmd.arg = vim.deepcopy(state.compiler_flags)
      cmd.arg[#cmd.arg + 1] = "-o"
      cmd.arg[#cmd.arg + 1] = state.exe_file
      cmd.arg[#cmd.arg + 1] = state.src_file

      state.command_cache.compile_cmd = cmd
      return cmd
    end

    commands.show_assembly = function()
      if state.command_cache.assemble_cmd then
        return state.command_cache.assemble_cmd
      end

      local cmd = vim.deepcopy(state.cmd_template)
      cmd.compiler = state.compiler

      cmd.arg = vim.deepcopy(state.compiler_flags)
      cmd.arg[#cmd.arg + 1] = "-c"
      cmd.arg[#cmd.arg + 1] = "-S"
      cmd.arg[#cmd.arg + 1] = "-o"
      cmd.arg[#cmd.arg + 1] = state.asm_file
      cmd.arg[#cmd.arg + 1] = state.src_file

      state.command_cache.assemble_cmd = cmd
      return cmd
    end
  end

  if has_type(LANG_TYPES.ASSEMBLED) then
    commands.compile = function()
      if state.command_cache.compile_cmd then
        return state.command_cache.compile_cmd
      end

      local cmd = vim.deepcopy(state.cmd_template)
      cmd.compiler = state.compiler

      cmd.arg = vim.deepcopy(state.compiler_flags)
      cmd.arg[#cmd.arg + 1] = "-o"
      cmd.arg[#cmd.arg + 1] = state.obj_file
      cmd.arg[#cmd.arg + 1] = state.src_file

      state.command_cache.compile_cmd = cmd
      return cmd
    end
  end

  if has_type(LANG_TYPES.LINKED) then
    commands.link = function()
      if state.command_cache.link_cmd then
        return state.command_cache.link_cmd
      end

      local cmd = vim.deepcopy(state.cmd_template)
      cmd.compiler = state.linker

      cmd.arg = vim.deepcopy(state.linker_flags)
      cmd.arg[#cmd.arg + 1] = "-o"
      cmd.arg[#cmd.arg + 1] = state.exe_file
      cmd.arg[#cmd.arg + 1] = state.obj_file

      state.command_cache.link_cmd = cmd
      return cmd
    end
  end

  return commands
end

return M
