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
  }

  local commands = {}

  for _, spec in ipairs(specs) do
    if state:has_type(spec.type) then
      commands[spec.name] = function()
        return cached(spec.name .. "_cmd", function()
          -- Resolve args (replace keys with state values if available)
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

  return commands
end

return M
