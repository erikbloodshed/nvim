local M = {}

local profiles = {
  compiled = {
    {
      name = "compile",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-o", "exe", "src_file" }
    },
    {
      name = "show_assembly",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-c", "-S", "-o", "asm_file", "src_file" }
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

  if spec.input_file and state[spec.input_file] then
    vim.list_extend(parts, { "<", state[spec.input_file] })
  end

  return spec.name == "run" and table.concat(parts, " ") or parts
end

M.create = function(state)
  local cmds = {}
  local specs = profiles[state.type] or {}

  for _, spec in ipairs(specs) do
    local key = spec.name .. "_cmd"
    cmds[spec.name] = function()
      return state:get_cached_command(key, function()
        return build_command(state, spec)
      end)
    end
  end

  return cmds
end

return M
