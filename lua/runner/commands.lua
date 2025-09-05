local M = {}

-- Hoist profiles (not rebuilt every call)
local profiles = {
  compiled = {
    {
      name = "compile",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-o", "exe_file", "src_file" }
    },
    {
      name =
      "show_assembly",
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-c", "-S", "-o", "asm_file", "src_file" }
    },
    {
      name =
      "run",
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

-- Lightweight cache
local function get_cached(cache, key, builder)
  local val = cache[key]
  if val ~= nil then return val end
  val = builder()
  cache[key] = val
  return val
end

M.create = function(state)
  local cache = state.command_cache
  local commands = {}

  for _, spec in ipairs(profiles[state.type] or {}) do
    local key = spec.name .. "_cmd"

    if spec.name == "run" then
      -- Run commands: direct string concatenation
      commands[spec.name] = function()
        return get_cached(cache, key, function()
          local cmd = state[spec.tool]

          -- flags
          local flags = spec.flags and state[spec.flags]
          if flags and #flags > 0 then
            cmd = cmd .. " " .. table.concat(flags, " ")
          end

          -- args
          local args = spec.args
          if args then
            for i = 1, #args do
              local arg = args[i]
              cmd = cmd .. " " .. (state[arg] or arg)
            end
          end

          -- cmd_args (string blob)
          local extra = spec.cmd_args and state[spec.cmd_args]
          if extra and extra ~= "" then
            cmd = cmd .. " " .. extra
          end

          -- input redirection
          local infile = spec.input_redirect and state[spec.input_redirect]
          if infile then
            cmd = cmd .. " < " .. infile
          end

          return cmd
        end)
      end
    else
      commands[spec.name] = function()
        return get_cached(cache, key, function()
          local resolved_args = {}
          local args = spec.args
          if args then
            for i = 1, #args do
              resolved_args[i] = state[args[i]] or args[i]
            end
          end
          return state:make_cmd(state[spec.tool], state[spec.flags], unpack(resolved_args))
        end)
      end
    end
  end

  return commands
end

return M
