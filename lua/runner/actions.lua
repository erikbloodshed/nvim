-- runner/actions.lua
local M = {}

-- Private function to create the low-level command-line execution details.
-- (Formerly the logic in `commands.lua`)
local function create_execution_commands(state)
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
    cmd.compiler = tool
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


-- Private function to create the high-level user action functions.
-- (Formerly the logic in `actions.lua`)
local function create_actions(state, commands, handler)
  local open_quickfix = require("runner.diagnostics").open_quickfixlist

  local function invalidate_cache()
    if state.has_type("interpreted") then
      state.command_cache.interpret_cmd = nil
      vim.notify("Interpreter flags set and cache cleared.", vim.log.levels.INFO)
      return
    end

    state.command_cache.compile_cmd = nil
    state.command_cache.link_cmd = nil

    if state.has_type("compiled") then
      state.command_cache.show_assembly_cmd = nil
    end

    vim.notify("Compiler flags set and cache cleared.", vim.log.levels.INFO)
  end

  local api, fn, utils = state.api, state.fn, state.utils
  local actions = {}

  local has_type = state.has_type
  actions.set_compiler_flags = function()
    vim.ui.input({
      prompt = "Enter compiler flags: ",
      default = table.concat(state.compiler_flags or {}, " ")
    }, function(flags_str)
      if flags_str == nil then return end -- User cancelled the input

      if flags_str ~= "" then
        state.compiler_flags = vim.split(flags_str, "%s+", { trimempty = true })
        invalidate_cache()
      else
        state.compiler_flags = {}
        invalidate_cache()
      end
    end)
  end

  actions.set_cmd_args = function()
    vim.ui.input({
      prompt = "Enter command-line arguments: ",
      default = state.cmd_args or ""
    }, function(args)
      if args ~= "" then
        state.cmd_args = args
        vim.notify("Command arguments set", vim.log.levels.INFO)
      else
        state.cmd_args = nil
        vim.notify("Command arguments cleared", vim.log.levels.INFO)
      end
    end)
  end

  actions.add_data_file = function()
    if state.data_path then
      local files = utils.scan_dir(state.data_path)

      if vim.tbl_isempty(files) then
        vim.notify("No files found in data directory: " .. state.data_path, vim.log.levels.WARN)
        return
      end

      vim.ui.select(files, {
        prompt = "Current: " .. (state.data_file or "None"),
        format_item = function(item)
          return fn.fnamemodify(item, ':t')
        end,
      }, function(choice)
        if choice then
          state.data_file = choice
          vim.notify("Data file set to: " .. fn.fnamemodify(choice, ':t'), vim.log.levels.INFO)
        end
      end)
    else
      vim.notify("Data directory not found", vim.log.levels.ERROR)
    end
  end

  actions.remove_data_file = function()
    if state.data_file then
      vim.ui.select({ "Yes", "No" }, {
        prompt = "Remove data file (" .. fn.fnamemodify(state.data_file, ':t') .. ")?",
      }, function(choice)
        if choice == "Yes" then
          state.data_file = nil
          vim.notify("Data file removed", vim.log.levels.INFO)
        end
      end)
    else
      vim.notify("No data file is currently set", vim.log.levels.WARN)
    end
  end

  actions.get_build_info = function()
    local flags = table.concat(state.compiler_flags or {}, " ")
    local lines = {
      "Filename          : " .. fn.fnamemodify(state.src_file, ':t'),
      "Filetype          : " .. state.filetype,
      "Language Type     : " .. state.type,
    }

    if has_type("compiled") or has_type("assembled") then
      lines[#lines + 1] = "Compiler          : " .. (state.compiler or "None")
      lines[#lines + 1] = "Compile Flags     : " .. (flags == "" and "None" or flags)
      lines[#lines + 1] = "Output Directory  : " ..
        (state.output_directory == "" and "None" or state.output_directory)
    end

    if has_type("assembled") then
      lines[#lines + 1] = "Linker            : " .. (state.linker or "None")
      lines[#lines + 1] = "Linker Flags      : " .. table.concat(state.linker_flags or {}, " ")
    end

    if has_type("interpreted") then
      lines[#lines + 1] = "Run Command       : " .. (state.compiler or "None")
    end

    vim.list_extend(lines, {
      "Data Directory    : " .. (state.data_path or "Not Found"),
      "Data File In Use  : " .. (state.data_file and fn.fnamemodify(state.data_file, ':t') or "None"),
      "Command Arguments : " .. (state.cmd_args or "None"),
      "Date Modified     : " .. utils.get_date_modified(state.src_file),
    })

    local ns_id = api.nvim_create_namespace("build_info_highlight")
    local buf_id = utils.open("Build Info", lines, "text")

    for idx = 1, #lines do
      local line = lines[idx]
      local colon_pos = line:find(":")
      if colon_pos and colon_pos > 1 then
        api.nvim_buf_set_extmark(buf_id, ns_id, idx - 1, 0, {
          end_col = colon_pos - 1,
          hl_group = "Keyword"
        })
      end
    end
  end

  if has_type("compiled") or has_type("assembled") then
    actions.compile = function()
      vim.cmd("silent! update")

      local success = handler.translate(state.hash_tbl, "compile", commands.compile())

      if not success then
        return false
      end

      if has_type("assembled") then
        success = handler.translate(state.hash_tbl, "link", commands.link())
        if not success then
          return false
        end
      end

      return true
    end
  end

  -- For interpreted languages, compile is a no-op
  if has_type("interpreted") then
    actions.compile = function()
      vim.cmd("silent! update")
      return true
    end
  end

  actions.run = function()
    local diagnostic_count = #vim.diagnostic.count(0, {
      severity = { vim.diagnostic.severity.ERROR }
    })

    if diagnostic_count > 0 then
      open_quickfix()
      return
    end

    local run_command
    if actions.compile() then
      if has_type("compiled") or has_type("assembled") then
        run_command = state.exe_file
      elseif has_type("interpreted") then
        local run_cmd = commands.interpret()
        if run_cmd then
          run_command = run_cmd.compiler
          if run_cmd.arg and #run_cmd.arg > 0 then
            run_command = run_command .. " " .. table.concat(run_cmd.arg, " ")
          end
        end
      end
    end

    if run_command then
      handler.run(run_command, state.cmd_args, state.data_file)
    end
  end

  if has_type("compiled") then
    actions.show_assembly = function()
      if commands.show_assembly and handler.translate(state.hash_tbl, "assemble", commands.show_assembly()) then
        utils.open(state.asm_file, utils.read_file(state.asm_file), "asm")
      end
    end
  end

  actions.open_quickfix = function()
    open_quickfix()
  end

  return actions
end

-- Private function to register user commands and keymaps.
-- (Formerly the logic in `command_registry.lua`)
local function register_user_commands(actions, state)
  local has_type = state.has_type

  local commands = {
    { name = "RunnerRun", action = actions.run, desc = "Run the current file" },
    { name = "RunnerSetFlags", action = actions.set_compiler_flags, desc = "Set compiler flags for the current session" },
    { name = "RunnerSetArgs", action = actions.set_cmd_args, desc = "Set command-line arguments" },
    { name = "RunnerAddDataFile", action = actions.add_data_file, desc = "Add a data file" },
    { name = "RunnerRemoveDataFile", action = actions.remove_data_file, desc = "Remove the current data file" },
    { name = "RunnerInfo", action = actions.get_build_info, desc = "Show build information" },
    { name = "RunnerProblems", action = actions.open_quickfix, desc = "Open quickfix window" },
  }

  if has_type("compiled") or has_type("assembled") then
    table.insert(commands, {
      name = "RunnerCompile",
      action = actions.compile,
      desc = "Compile the current file"
    })
  end

  if has_type("compiled") and actions.show_assembly then
    table.insert(commands, {
      name = "RunnerShowAssembly",
      action = actions.show_assembly,
      desc = "Show assembly output"
    })
  end

  if vim.api.nvim_create_user_command then
    for _, cmd in ipairs(commands) do
      vim.api.nvim_create_user_command(cmd.name, cmd.action, { desc = cmd.desc })
    end
  end

  if state.keymaps then
    for _, mapping in ipairs(state.keymaps) do
      if mapping.action and actions[mapping.action] then
        vim.keymap.set(
          mapping.mode or "n",
          mapping.key,
          actions[mapping.action],
          { buffer = 0, desc = mapping.desc }
        )
      end
    end
  end
end

--- Public setup function to orchestrate command and action creation and registration.
M.init = function(state, handler)
  local commands = create_execution_commands(state)
  local actions = create_actions(state, commands, handler)
  register_user_commands(actions, state)
end

return M
