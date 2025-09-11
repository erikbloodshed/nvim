--- @diagnostic disable: missing-fields
local api, fn, log, notify = vim.api, vim.fn, vim.log.levels, vim.notify
local utils = require("xrun.utils")

local has_errors = function()
  if #vim.diagnostic.count(0, { severity = { vim.diagnostic.severity.ERROR } }) > 0 then
    require("xrun.diagnostics").open_quickfixlist()
    return true
  end
  return false
end

local execute = function(c, callback)
  vim.system(c, { text = true }, function(r)
    vim.schedule(function()
      if r.code == 0 then
        notify(string.format("Compilation successful with exit code %s.", r.code), log.INFO)
        callback(true)
      else
        if r.stderr and r.stderr ~= "" then
          notify(r.stderr, log.ERROR)
        end
        callback(false)
      end
    end)
  end)
end

local M = {}

M.create = function(state, cmd)
  local cache_proc = function(key, command, on_success, callback)
    local hash = state:get_buffer_hash()

    if state.hash_tbl[key] and state.hash_tbl[key] == hash then
      notify(string.format("Source code is already processed for %s.", key), log.WARN)
      callback(true)
      return
    end

    execute(command, function(success)
      state.hash_tbl[key] = success and hash or nil
      if success and on_success then
        on_success()
      end
      callback(success)
    end)
  end

  local run_in_terminal = function()
    vim.cmd("ToggleTerm")
    vim.defer_fn(function()
      local job_id = vim.bo.channel
      fn.chansend(job_id, cmd.run() .. "\n")
    end, 100)
  end

  local actions = {}

  actions.run = function()
    if has_errors() then return end
    vim.api.nvim_cmd({ cmd = "update", bang = true, mods = { emsg_silent = true } }, {})

    if not cmd.compile then
      run_in_terminal()
      return
    end

    cache_proc("compile", cmd.compile(), function() state:update_deps() end, function(success)
      if not success then return end

      if cmd.link then
        execute(cmd.link(), function(link_success)
          if not link_success then return end
          run_in_terminal()
        end)
      else
        run_in_terminal()
      end
    end)
  end

  actions.show_assembly = function()
    if not cmd.show_assembly then return end
    vim.api.nvim_cmd({ cmd = "update", bang = true, mods = { emsg_silent = true } }, {})

    if has_errors() then return end

    cache_proc("assemble", cmd.show_assembly(), nil, function(success)
      if success then
        utils.open(state.asm_file, utils.read_file(state.asm_file), "asm")
      end
    end)
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
    local lang_type = state.type
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
