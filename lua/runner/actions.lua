local handler = require("runner.handler")
local open_quickfix = require("runner.diagnostics").open_quickfixlist
local log_levels = vim.log.levels
local api, fn, notify = vim.api, vim.fn, vim.notify
local utils = require("runner.utils")

local M = {}

M.create = function(state, cmd)
  local lang_type = state.type
  local actions = {}

  actions.set_compiler_flags = function()
    vim.ui.input({
      prompt = "Enter compiler flags: ",
      default = table.concat(state.compiler_flags or {}, " ")
    }, function(flags_str)
      if flags_str == nil then return end -- User cancelled
      state.compiler_flags = flags_str ~= "" and vim.split(flags_str, "%s+", { trimempty = true }) or {}
      state:invalidate_cache()
      local msg = state.type == "interpreted" and "Interpreter flags set and cache cleared."
        or "Compiler flags set and cache cleared."
      notify(msg, log_levels.INFO)
    end)
  end

  actions.set_cmd_args = function()
    vim.ui.input({
      prompt = "Enter command-line arguments: ",
      default = state.cmd_args or ""
    }, function(args)
      if args == nil then return end
      state.cmd_args = args ~= "" and args or nil
      state.command_cache.run_cmd = nil
      local msg = args ~= "" and "Command arguments set" or "Command arguments cleared"
      notify(msg, log_levels.INFO)
    end)
  end

  actions.add_data_file = function()
    if not state.data_path then
      notify("Data directory not found", log_levels.ERROR)
      return
    end

    local files = utils.scan_dir(state.data_path)
    if vim.tbl_isempty(files) then
      notify("No files found in data directory: " .. state.data_path, log_levels.WARN)
      return
    end

    vim.ui.select(files, {
      prompt = "Current: " .. (state.data_file or "None"),
      format_item = function(item) return fn.fnamemodify(item, ':t') end,
    }, function(choice)
      if choice then
        state.data_file = choice
        state.command_cache.run_cmd = nil
        notify("Data file set to: " .. fn.fnamemodify(choice, ':t'), log_levels.INFO)
      end
    end)
  end

  actions.remove_data_file = function()
    local current_file = state.data_file
    if not current_file then
      notify("No data file is currently set", log_levels.WARN)
      return
    end

    vim.ui.select({ "Yes", "No" }, {
      prompt = "Remove data file (" .. current_file .. ")?",
    }, function(choice)
      if choice == "Yes" then
        state.data_file = nil
        state.command_cache.run_cmd = nil
        notify("Data file removed", log_levels.INFO)
      end
    end)
  end

  actions.get_build_info = function()
    local flags = table.concat(state.compiler_flags or {}, " ")
    local lines = {
      "Filename          : " .. fn.fnamemodify(state.src_file, ':t'),
      "Filetype          : " .. vim.bo.filetype,
      "Language Type     : " .. lang_type,
    }

    if lang_type == "compiled" or lang_type == "assembled" then
      lines[#lines + 1] = "Compiler          : " .. (state.compiler or "None")
      lines[#lines + 1] = "Compile Flags     : " .. (flags == "" and "None" or flags)
      lines[#lines + 1] = "Output Directory  : " .. (state.output_directory == "" and "None" or state.output_directory)
    end

    if lang_type == "assembled" then
      lines[#lines + 1] = "Linker            : " .. (state.linker or "None")
      lines[#lines + 1] = "Linker Flags      : " .. table.concat(state.linker_flags or {}, " ")
    end

    if lang_type == "interpreted" then
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

  actions.compile = function()
    vim.cmd("silent! update")

    if lang_type == "interpreted" then return true end

    local buffer_hash = state:get_buffer_hash()
    local success = true

    if state.hash_tbl["compile"] == buffer_hash then
      notify("Source code is already processed for compile.", vim.log.levels.WARN)
    else
      success = handler.translate("compile", cmd.compile())
      if success then
        state.hash_tbl["compile"] = buffer_hash
      end
    end

    if not success then return false end

    if lang_type == "assembled" then
      if state.hash_tbl["link"] == buffer_hash then
        notify("Source code is already processed for link.", vim.log.levels.WARN)
      else
        success = handler.translate("link", cmd.link())
        if success then
          state.hash_tbl["link"] = buffer_hash
        end
      end
    end

    return success
  end

  actions.show_assembly = function()
    if not cmd.show_assembly then return end
    vim.cmd("silent! update")

    if #vim.diagnostic.count(0, { severity = { vim.diagnostic.severity.ERROR } }) > 0 then
      open_quickfix()
      return
    end

    local buffer_hash = state:get_buffer_hash()
    local success = true

    if state.hash_tbl["assemble"] == buffer_hash then
      notify("Source code is already processed for assemble.", vim.log.levels.WARN)
    else
      success = handler.translate("assemble", cmd.show_assembly())
      if success then
        state.hash_tbl["assemble"] = buffer_hash
      end
    end

    if success then
      utils.open(state.asm_file, utils.read_file(state.asm_file), "asm")
    end
  end

  actions.run = function()
    if #vim.diagnostic.count(0, { severity = { vim.diagnostic.severity.ERROR } }) > 0 then
      open_quickfix()
      return
    end

    if actions.compile() then
      handler.run(cmd.run())
    end
  end

  actions.open_quickfix = function()
    open_quickfix()
  end

  return actions
end

return M
