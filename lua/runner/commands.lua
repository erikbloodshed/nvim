local M = {}

M.create = function(state)
  local has_type = state.has_type

  local function cached(key, build)
    local cache = state.command_cache
    if cache[key] then return cache[key] end
    local cmd = build()
    cache[key] = cmd
    return cmd
  end

  local function make_cmd(tool, flags, ...)
    local cmd = vim.deepcopy(state.cmd_template)
    cmd.compiler = tool -- field name kept for compatibility
    cmd.arg = vim.deepcopy(flags)
    vim.list_extend(cmd.arg, { ... })
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
    if has_type(spec.type) then
      commands[spec.name] = function()
        return cached(spec.name .. "_cmd", function()
          -- Resolve args (replace keys with state values if available)
          local resolved = {}
          for _, a in ipairs(spec.args) do
            resolved[#resolved + 1] = state[a] or a
          end
          return make_cmd(state[spec.tool], state[spec.flags], unpack(resolved))
        end)
      end
    end
  end

  return commands
end

return M
