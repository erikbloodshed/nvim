local open_quickfix = require("runner.diagnostics").open_quickfixlist
local log_levels = vim.log.levels

local M = {}

M.create = function(state, cmd)
  local handler = require("runner.handler")
  local actions = {}

  actions.set_compiler_flags = function()
    vim.ui.input({
      prompt = "Enter compiler flags: ",
      default = table.concat(state.compiler_flags or {}, " ")
    }, function(flags_str)
      if flags_str == nil then return end -- User cancelled

      local flags = flags_str ~= "" and vim.split(flags_str, "%s+", { trimempty = true }) or {}
      local cache_type = state:set_compiler_flags(flags)

      local msg = cache_type == "interpreted" and "Interpreter flags set and cache cleared."
        or "Compiler flags set and cache cleared."
      vim.notify(msg, log_levels.INFO)
    end)
  end

  actions.set_cmd_args = function()
    vim.ui.input({
      prompt = "Enter command-line arguments: ",
      default = state.cmd_args or ""
    }, function(args)
      if args == nil then return end -- User cancelled

      state:set_cmd_args(args ~= "" and args or nil)

      local msg = args ~= "" and "Command arguments set" or "Command arguments cleared"
      vim.notify(msg, log_levels.INFO)
    end)
  end

  actions.add_data_file = function()
    if not state.data_path then
      vim.notify("Data directory not found", log_levels.ERROR)
      return
    end

    local files = state.utils.scan_dir(state.data_path)
    if vim.tbl_isempty(files) then
      vim.notify("No files found in data directory: " .. state.data_path, log_levels.WARN)
      return
    end

    vim.ui.select(files, {
      prompt = "Current: " .. (state:get_data_filename() or "None"),
      format_item = function(item) return state.fn.fnamemodify(item, ':t') end,
    }, function(choice)
      if choice then
        state:set_data_file(choice)
        vim.notify("Data file set to: " .. state.fn.fnamemodify(choice, ':t'), log_levels.INFO)
      end
    end)
  end

  actions.remove_data_file = function()
    local current_file = state:get_data_filename()
    if not current_file then
      vim.notify("No data file is currently set", log_levels.WARN)
      return
    end

    vim.ui.select({ "Yes", "No" }, {
      prompt = "Remove data file (" .. current_file .. ")?",
    }, function(choice)
      if choice == "Yes" then
        state:remove_data_file()
        vim.notify("Data file removed", log_levels.INFO)
      end
    end)
  end

  actions.get_build_info = function()
    local lines = state:get_build_info()
    local ns_id = state.api.nvim_create_namespace("build_info_highlight")
    local buf_id = state.utils.open("Build Info", lines, "text")

    for idx = 1, #lines do
      local line = lines[idx]
      local colon_pos = line:find(":")
      if colon_pos and colon_pos > 1 then
        state.api.nvim_buf_set_extmark(buf_id, ns_id, idx - 1, 0, {
          end_col = colon_pos - 1,
          hl_group = "Keyword"
        })
      end
    end
  end

  actions.compile = function()
    vim.cmd("silent! update")

    if state:has_type("interpreted") then
      return true
    end

    local buffer_hash = state:get_buffer_hash()

    if state.hash_tbl["compile"] == buffer_hash then
      vim.notify("Source code is already processed for compile.", vim.log.levels.WARN)
    else
      local success = handler.translate("compile", cmd.compile())
      if not success then return false end
      state.hash_tbl["compile"] = buffer_hash
    end

    if state:has_type("assembled") then
      if state.hash_tbl["link"] == buffer_hash then
        vim.notify("Source code is already processed for link.", vim.log.levels.WARN)
      else
        local success = handler.translate("link", cmd.link())
        if not success then return false end
        state.hash_tbl["link"] = buffer_hash
      end
    end

    return true
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

  if state:has_type("compiled") then
    actions.show_assembly = function()
      if not cmd.show_assembly then return end

      local buffer_hash = state:get_buffer_hash()
      local success = true

      if state.hash_tbl["assemble"] == buffer_hash then
        vim.notify("Source code is already processed for assemble.", vim.log.levels.WARN)
      else
        success = handler.translate("assemble", cmd.show_assembly())
        if success then
          state.hash_tbl["assemble"] = buffer_hash
        end
      end

      if success then
        state.utils.open(state.asm_file, state.utils.read_file(state.asm_file), "asm")
      end
    end
  end

  return actions
end

return M
