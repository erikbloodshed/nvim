local M = {}

M.create = function(state)
  local function cached(key, build_fn)
    local cache = state.command_cache
    if cache[key] then return cache[key] end
    local cmd = build_fn()
    cache[key] = cmd
    return cmd
  end

  local specs = {
    {
      name = "compile",
      type = "compiled",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-o", "exe_file", "src_file" },
    },
    {
      name = "show_assembly",
      type = "compiled",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-c", "-S", "-o", "asm_file", "src_file" },
    },
    {
      name = "compile",
      type = "assembled",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-o", "obj_file", "src_file" },
    },
    {
      name = "link",
      type = "assembled",
      tool = "linker",
      flags = "linker_flags",
      args = { "-o", "exe_file", "obj_file" },
    },
    {
      name = "interpret",
      type = "interpreted",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "src_file" },
    },
    -- New run specs
    {
      name = "run",
      type = "compiled",
      tool = "exe_file",        -- Use the executable directly
      flags = "cmd_args",       -- Use command args as flags
      args = {},
      input_file = "data_file", -- Special field for input redirection
    },
    {
      name = "run",
      type = "assembled",
      tool = "exe_file",
      flags = "cmd_args",
      args = {},
      input_file = "data_file",
    },
    {
      name = "run",
      type = "interpreted",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "src_file" },
      extra_flags = "cmd_args", -- Additional args after the main command
      input_file = "data_file",
    },
  }

  local commands = {}
  -- Handle regular commands with the existing simple loop
  for _, spec in ipairs(specs) do
    if state:has_type(spec.type) then
      commands[spec.name] = function()
        return cached(spec.name .. "_cmd", function()
          local resolved_args = {}
          for _, arg in ipairs(spec.args) do
            resolved_args[#resolved_args + 1] = state[arg] or arg
          end

          return state:make_cmd(
            state[spec.tool],
            state[spec.flags],
            unpack(resolved_args)
          )
        end)
      end
    end
  end

  -- Add run command separately - much cleaner!
  commands.run = function()
    return cached("run_cmd", function()
      local parts = {}

      if state:has_type("compiled") or state:has_type("assembled") then
        -- Just run the executable
        table.insert(parts, state.exe_file)
      else
        -- Use interpreter
        table.insert(parts, state.compiler)
        if state.compiler_flags then
          vim.list_extend(parts, state.compiler_flags)
        end
        table.insert(parts, state.src_file)
      end

      -- Add command arguments
      if state.cmd_args then
        table.insert(parts, state.cmd_args)
      end

      local cmd = table.concat(parts, " ")

      -- Add input redirection
      if state.data_file then
        cmd = cmd .. " < " .. state.data_file
      end

      return cmd
    end)
  end

  return commands
end

return M
