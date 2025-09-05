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

  for _, spec in ipairs(specs) do
    if state:has_type(spec.type) then
      commands[spec.name] = function()
        return cached(spec.name .. "_cmd", function()
          -- Handle special run command logic
          if spec.name == "run" then
            local resolved_args = {}
            for _, arg in ipairs(spec.args) do
              resolved_args[#resolved_args + 1] = state[arg] or arg
            end

            local cmd_parts = { state[spec.tool] }

            -- Add flags
            if spec.flags and state[spec.flags] then
              if type(state[spec.flags]) == "table" then
                vim.list_extend(cmd_parts, state[spec.flags])
              else
                table.insert(cmd_parts, state[spec.flags])
              end
            end

            -- Add resolved args
            vim.list_extend(cmd_parts, resolved_args)

            -- Add extra flags (for interpreted languages)
            if spec.extra_flags and state[spec.extra_flags] then
              table.insert(cmd_parts, state[spec.extra_flags])
            end

            local base_cmd = table.concat(cmd_parts, " ")

            -- Add input redirection if data file exists
            if spec.input_file and state[spec.input_file] then
              base_cmd = base_cmd .. " < " .. state[spec.input_file]
            end

            return base_cmd
          else
            -- Regular command logic
            local resolved_args = {}
            for _, arg in ipairs(spec.args) do
              resolved_args[#resolved_args + 1] = state[arg] or arg
            end

            return state:make_cmd(
              state[spec.tool],
              state[spec.flags],
              unpack(resolved_args)
            )
          end
        end)
      end
    end
  end

  return commands
end

return M
