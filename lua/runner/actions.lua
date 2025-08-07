-- In actions.lua
local M = {}

M.create = function(state, commands, handler)
  local open_quickfix = require("runner.diagnostics").open_quickfixlist
  local api = state.api
  local fn = state.fn
  local utils = state.utils
  local LANG_TYPES = require("runner.config").LANGUAGE_TYPES
  local actions = {}

  -- Helper to check if language belongs to a type
  local has_type = function(type)
    for _, lang_type in ipairs(state.language_types) do
      if lang_type == type then
        return true
      end
    end
    return false
  end

  -- Common actions for all language types
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
      "Language Type     : " .. table.concat(state.language_types or {}, ", "),
    }

    if has_type(LANG_TYPES.COMPILED) or has_type(LANG_TYPES.ASSEMBLED) then
      lines[#lines + 1] = "Compiler          : " .. (state.compiler or "None")
      lines[#lines + 1] = "Compile Flags     : " .. (flags == "" and "None" or flags)
      lines[#lines + 1] = "Output Directory  : " ..
          (state.output_directory == "" and "None" or state.output_directory)
    end

    if has_type(LANG_TYPES.LINKED) then
      lines[#lines + 1] = "Linker            : " .. (state.linker or "None")
      lines[#lines + 1] = "Linker Flags      : " .. table.concat(state.linker_flags or {}, " ")
    end

    if has_type(LANG_TYPES.INTERPRETED) then
      lines[#lines + 1] = "Run Command       : " .. (state.run_cmd or "None")
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

  -- Language type specific actions
  if has_type(LANG_TYPES.COMPILED) or has_type(LANG_TYPES.ASSEMBLED) then
    actions.compile = function()
      vim.cmd("silent! update")

      local success = handler.translate(state.hash_tbl, "compile", commands.compile())

      if not success then
        return false
      end

      if has_type(LANG_TYPES.LINKED) then
        success = handler.translate(state.hash_tbl, "link", commands.link())
        if not success then
          return false
        end
      end

      return true
    end
  end

  -- For interpreted languages, compile is a no-op
  if has_type(LANG_TYPES.INTERPRETED) then
    actions.compile = function()
      vim.cmd("silent! update")
      return true
    end
  end

  -- Run action based on language type
  actions.run = function()
    local diagnostic_count = #vim.diagnostic.count(0, {
      severity = { vim.diagnostic.severity.ERROR }
    })

    if diagnostic_count > 0 then
      open_quickfix()
      return
    end

    if actions.compile() then
      if has_type(LANG_TYPES.COMPILED) or has_type(LANG_TYPES.LINKED) then
        handler.run(state.exe_file, state.cmd_args, state.data_file)
      elseif has_type(LANG_TYPES.INTERPRETED) then
        handler.run(state.run_cmd .. " " .. state.src_file, state.cmd_args, state.data_file)
      end
    end
  end

  -- Show assembly action only for compiled languages
  if has_type(LANG_TYPES.COMPILED) then
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
