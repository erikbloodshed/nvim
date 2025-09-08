local M = {}

local profiles = {
  compiled = {
    {
      name = "compile",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-o", "exe_file", "src_file" }
    },
    {
      name = "show_assembly",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-c", "-S", "-o", "asm_file", "src_file" }
    },
    {
      name = "run",
      tool = "exe_file",
      cmd_args = "cmd_args",
      input_redirect = "data_file"
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
      args = { "-o", "exe_file", "obj_file" }
    },
    {
      name = "run",
      tool = "exe_file",
      cmd_args = "cmd_args",
      input_redirect = "data_file"
    },
  },
  interpreted = {
    {
      name = "run",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "src_file" },
      cmd_args = "cmd_args",
      input_redirect = "data_file"
    },
  },
}

local function build_command(state, spec)
  local cmd = state[spec.tool]
  local parts = { cmd }

  if spec.flags and state[spec.flags] and #state[spec.flags] > 0 then
    vim.list_extend(parts, state[spec.flags])
  end

  if spec.args then
    local resolved_args = vim.tbl_map(function(arg) return state[arg] or arg end, spec.args)
    vim.list_extend(parts, resolved_args)
  end

  if spec.cmd_args and state[spec.cmd_args] and state[spec.cmd_args] ~= "" then
    table.insert(parts, state[spec.cmd_args])
  end

  if spec.input_redirect and state[spec.input_redirect] then
    table.insert(parts, "< " .. state[spec.input_redirect])
  end

  if spec.name == "run" then
    -- For run commands, return as shell command string (for terminal execution)
    return table.concat(parts, " ")
  else
    -- For compile/link commands, return as list for process.execute()
    return parts
  end
end

M.create = function(state)
  local commands = {}
  local type_specs = profiles[state.type] or {}

  for _, spec in ipairs(type_specs) do
    local key = spec.name .. "_cmd"
    commands[spec.name] = function()
      return state:get_cached_command(key, function()
        return build_command(state, spec)
      end)
    end
  end

  return commands
end

return M
