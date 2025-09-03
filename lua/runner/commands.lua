local M = {}

M.create = function(state)
  local LANG_TYPES = require("runner.config").LANGUAGE_TYPES
  local language_types = state.language_types or {}

  -- Build a set for quick membership checks
  local type_set = {}
  for _, t in ipairs(language_types) do type_set[t] = true end
  local has_type = function(t) return type_set[t] end

  -- Cache wrapper
  local function cached(key, build)
    local cache = state.command_cache
    if cache[key] then return cache[key] end
    local cmd = build()
    cache[key] = cmd
    return cmd
  end

  -- Command builder
  local function make_cmd(tool, flags, ...)
    local cmd = vim.deepcopy(state.cmd_template)
    cmd.compiler = tool -- field name kept for compatibility
    cmd.arg = vim.deepcopy(flags)
    vim.list_extend(cmd.arg, { ... })
    return cmd
  end

  -- Command specs, gated by language type
  local specs = {
    {
      name = "compile",
      type = LANG_TYPES.COMPILED,
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-o", "exe_file", "src_file" },
    },
    {
      name = "show_assembly",
      type = LANG_TYPES.COMPILED,
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-c", "-S", "-o", "asm_file", "src_file" },
    },
    {
      name = "compile",
      type = LANG_TYPES.ASSEMBLED,
      tool = "compiler",
      flags = "compiler_flags",
      args = { "-o", "obj_file", "src_file" },
    },
    {
      name = "link",
      type = LANG_TYPES.LINKED,
      tool = "linker",
      flags = "linker_flags",
      args = { "-o", "exe_file", "obj_file" },
    },
    {
      name = "interpret",
      type = LANG_TYPES.INTERPRETED,
      tool = "compiler",        -- For interpreted languages, this is the interpreter
      flags = "compiler_flags", -- These become interpreter flags
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
