local open_quickfix = require("runner.diagnostics").open_quickfixlist
local log_levels = vim.log.levels

local function invalidate_cache(state)
  state.command_cache.run_cmd = nil

  if state.has_type("interpreted") then
    state.command_cache.interpret_cmd = nil
    vim.notify("Interpreter flags set and cache cleared.", log_levels.INFO)
    return
  end

  state.command_cache.compile_cmd = nil
  state.command_cache.link_cmd = nil

  if state.has_type("compiled") then
    state.command_cache.show_assembly_cmd = nil
  end

  vim.notify("Compiler flags set and cache cleared.", log_levels.INFO)
end

local M = {}

M.create = function(state, commands, handler)
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
        invalidate_cache(state)
      else
        state.compiler_flags = {}
        invalidate_cache(state)
      end
    end)
  end

  actions.set_cmd_args = function()
    vim.ui.input({
      prompt = "Enter command-line arguments: ",
      default = state.cmd_args or ""
    }, function(args)
      if args ~= "" then
        state.command_cache.run_cmd = nil
        state.cmd_args = args
        vim.notify("Command arguments set", log_levels.INFO)
      else
        state.cmd_args = nil
        vim.notify("Command arguments cleared", log_levels.INFO)
      end
    end)
  end

  actions.add_data_file = function()
    if state.data_path then
      local files = utils.scan_dir(state.data_path)

      if vim.tbl_isempty(files) then
        vim.notify("No files found in data directory: " .. state.data_path, log_levels.WARN)
        return
      end

      vim.ui.select(files, {
        prompt = "Current: " .. (state.data_file or "None"),
        format_item = function(item)
          return fn.fnamemodify(item, ':t')
        end,
      }, function(choice)
        if choice then
          state.command_cache.run_cmd = nil
          state.data_file = choice
          vim.notify("Data file set to: " .. fn.fnamemodify(choice, ':t'), log_levels.INFO)
        end
      end)
    else
      vim.notify("Data directory not found", log_levels.ERROR)
    end
  end

  actions.remove_data_file = function()
    if state.data_file then
      vim.ui.select({ "Yes", "No" }, {
        prompt = "Remove data file (" .. fn.fnamemodify(state.data_file, ':t') .. ")?",
      }, function(choice)
        if choice == "Yes" then
          state.command_cache.run_cmd = nil
          state.data_file = nil
          vim.notify("Data file removed", log_levels.INFO)
        end
      end)
    else
      vim.notify("No data file is currently set", log_levels.WARN)
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

    local run_command = state.command_cache.run_cmd

    if not run_command then
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

      if state.cmd_args then
        run_command = run_command .. " " .. state.cmd_args
      end

      if state.data_file then
        run_command = run_command .. " < " .. state.data_file
      end

      state.command_cache.run_cmd = run_command
    end

    handler.run(run_command)
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

return M
