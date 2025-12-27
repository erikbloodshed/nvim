local M = {}

local profiles = {
  compiled = {
    {
      name = "compile",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-MMD", "-MF", "dep_file", "-o", "exe", "src_file" }
    },
    {
      name = "show_assembly",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-c", "-S", "-masm=intel", "-o", "asm_file", "src_file" }
    },
    {
      name = "run",
      tool = "exe",
      cmd_args = "cmd_args",
      input_file = "data_file"
    },
  },
  assembled = {
    {
      name = "compile",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-o", "obj_file", "src_file" }
    },
    {
      name = "link",
      tool = "linker",
      flags = "linker_flags",
      args = { "-o", "exe", "obj_file" }
    },
    {
      name = "run",
      tool = "exe",
      cmd_args = "cmd_args",
      input_file = "data_file"
    },
  },
  interpreted = {
    {
      name = "run",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "src_file" },
      cmd_args = "cmd_args",
      input_file = "data_file"
    },
  },
}

M.create = function(state)
  local handlers = {}

  handlers.default = function(spec, parts)
    local flags, args = spec.flags, spec.args

    if flags and state[flags] and #state[flags] > 0 then
      vim.list_extend(parts, state[flags])
    end

    if args then
      local resolved_args = vim.tbl_map(function(arg)
        return state[arg] or arg
      end, args)
      vim.list_extend(parts, resolved_args)
    end

    return parts
  end

  handlers.run = function(spec, parts)
    parts = handlers.default(spec, parts)
    local cmd_args, input_file = spec.cmd_args, spec.input_file

    if cmd_args and state[cmd_args] and state[cmd_args] ~= "" then
      table.insert(parts, state[cmd_args])
    end

    if input_file and state[input_file] then
      vim.list_extend(parts, { "<", state[input_file] })
    end

    return table.concat(parts, " ")
  end

  local cmds = {}
  local specs = profiles[state.type] or {}

  for _, spec in ipairs(specs) do
    local name = spec.name
    cmds[name] = function()
      return state:get_cached_command(name .. "_cmd", function()
        local handler = handlers[name] or handlers.default
        return handler(spec, { state[spec.tool] })
      end)
    end
  end

  return cmds
end

return M
