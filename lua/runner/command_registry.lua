local M = {}

M.register = function(actions, state)
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

return M
