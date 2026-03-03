local api = vim.api

local M = {}

function M.setup(terminal_manager, user_commands)
  -- Existing ToggleTerminal command
  api.nvim_create_user_command('ToggleTerminal', function(opts)
    local name = opts.args
    if name == '' then
      vim.notify("Usage: :ToggleTerminal <terminal_name>", vim.log.levels.ERROR)
      return
    end

    local term = terminal_manager.get_terminal(name)
    if not term then
      vim.notify(string.format("Terminal '%s' not found. Create it first.", name), vim.log.levels.ERROR)
      return
    end

    term:toggle()
  end, {
    nargs = 1,
    complete = terminal_manager.list_terminals,
    desc = 'Toggle any terminal by name',
  })

  -- New: Run command for direct execution
  api.nvim_create_user_command('Run', function(opts)
    local path = vim.fn.expand(opts.args)

    -- if vim.fn.executable(path) ~= 1 then
    --   vim.notify(string.format("'%s' is not an executable file.", path), vim.log.levels.ERROR)
    --   return
    -- end

    -- Use a dedicated "runner" terminal instance
    local term = terminal_manager.get_terminal("runner")
    if not term then
      term = terminal_manager.create_terminal("runner", {
        title = "Runner",
      })
    end

    -- Update UI title dynamically to reflect the running file
    term.config.title = "Run: " .. vim.fn.fnamemodify(path, ":t")
    term:open(path)
  end, {
    nargs = 1,
    complete = 'file',
    desc = 'Run an executable in a floating terminal',
  })

  if not user_commands or type(user_commands) ~= 'table' then
    return
  end

  for _, cmd_config in ipairs(user_commands) do
    local cmd_name = cmd_config.name
    local term_name = cmd_config.terminal

    if not cmd_name or not term_name then
      vim.notify("Term: Invalid command config. Requires 'name' and 'terminal'.", vim.log.levels.WARN)
      goto continue
    end

    api.nvim_create_user_command(cmd_name, function()
      local terminal = terminal_manager.get_terminal(term_name)
      if terminal then
        terminal:toggle()
      else
        vim.notify(string.format("Terminal '%s' not found for command '%s'", term_name, cmd_name),
          vim.log.levels.ERROR)
      end
    end, {
      desc = cmd_config.desc or string.format("Toggle the '%s' terminal", term_name)
    })

    ::continue::
  end
end

return M
