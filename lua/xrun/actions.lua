local api, fn, log, notify = vim.api, vim.fn, vim.log.levels, vim.notify
local utils = require("xrun.utils")

local M = {}

M.create = function(state, cmd)
  local cache_proc = function(hash, key, command)
    local status = true

    if state.hash_tbl[key] and state.hash_tbl[key] == hash then
      notify(string.format("Source code is already processed for %s.", key), log.WARN)
    else
      status = utils.translate(command)
      state.hash_tbl[key] = status and hash or nil
    end

    return status
  end

  local lang_type = state.type
  local actions = {}

  actions.compile = function()
    vim.cmd("silent! update")

    if lang_type == "interpreted" then return true end

    local buffer_hash = state:get_buffer_hash()
    local success = cache_proc(buffer_hash, "compile", cmd.compile())

    if lang_type == "assembled" and success then
      success = cache_proc(buffer_hash, "link", cmd.link())
    end

    return success
  end

  actions.show_assembly = function()
    if not cmd.show_assembly then return end
    vim.cmd("silent! update")

    if utils.has_errors() then return end

    local buffer_hash = state:get_buffer_hash()
    local success = cache_proc(buffer_hash, "assemble", cmd.show_assembly())
    if success then
      utils.open(state.asm_file, utils.read_file(state.asm_file), "asm")
    end
  end

  actions.run = function()
    if utils.has_errors() then return end
    if actions.compile() then utils.run(cmd.run()) end
  end

  actions.open_quickfix = function()
    require("xrun.diagnostics").open_quickfixlist()
  end

  actions.set_compiler_flags = function()
    vim.ui.input({
      prompt = "Enter compiler flags: ",
      default = table.concat(state.compiler_flags or {}, " ")
    }, function(flags_str)
      if flags_str == nil then return end
      state:set_compiler_flags(flags_str)
      local msg = state.type == "interpreted" and "Interpreter flags set and cache cleared."
        or "Compiler flags set and cache cleared."
      notify(msg, log.INFO)
    end)
  end

  actions.set_cmd_args = function()
    vim.ui.input({
      prompt = "Enter command-line arguments: ",
      default = state.cmd_args or ""
    }, function(args)
      if args == nil then return end
      state:set_cmd_args(args)
      local msg = args ~= "" and "Command arguments set" or "Command arguments cleared"
      notify(msg, log.INFO)
    end)
  end

  actions.add_data_file = function()
    if not state.data_path then
      notify("Data directory not found", log.ERROR)
      return
    end

    local files = utils.get_files(state.data_path)
    if vim.tbl_isempty(files) then
      notify("No files found in data directory: " .. state.data_path, log.WARN)
      return
    end

    vim.ui.select(files, {
      prompt = "Current: " .. (state.data_file or "None"),
      format_item = function(item) return fn.fnamemodify(item, ':t') end,
    }, function(choice)
      if choice then
        state:set_data_file(choice)
        notify("Data file set to: " .. choice, log.WARN)
      end
    end)
  end

  actions.remove_data_file = function()
    local current_file = state.data_file
    if not current_file then
      notify("No data file is currently set", log.WARN)
      return
    end
    state:set_data_file(nil)
    notify(string.format("Data file '%s' removed", current_file), log.WARN)
  end

  actions.get_build_info = function()
    local flags = table.concat(state.compiler_flags or {}, " ")
    local lines = {
      "Filename      : " .. fn.fnamemodify(state.src_file, ':t'),
      "Filetype      : " .. vim.bo.filetype,
      "Language Type : " .. lang_type,
      "Date Modified : " .. utils.get_date_modified(state.src_file),
    }

    if lang_type == "compiled" or lang_type == "assembled" then
      lines[#lines + 1] = "Compiler      : " .. (state.compiler or "None")
      lines[#lines + 1] = "Flags         : " .. (flags == "" and "None" or flags)
      lines[#lines + 1] = "Output Dir    : " .. (state.outdir == "" and "None" or state.outdir)
    end

    if lang_type == "assembled" then
      lines[#lines + 1] = "Linker        : " .. (state.linker or "None")
      lines[#lines + 1] = "Linker Flags  : " .. table.concat(state.linker_flags or {}, " ")
    end

    if lang_type == "interpreted" then
      lines[#lines + 1] = "Interpreter   : " .. (state.compiler or "None")
    end

    vim.list_extend(lines, {
      "Data Dir      : " .. (state.data_path or "Not Found"),
      "Data File     : " .. (state.data_file and fn.fnamemodify(state.data_file, ':t') or "None"),
      "Arguments     : " .. (state.cmd_args or "None"),
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

  return actions
end

return M
