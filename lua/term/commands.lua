local api = vim.api

local M = {}

function M.setup(terminal_manager, user_commands)
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
    nargs    = 1,
    complete = terminal_manager.list_terminals,
    desc     = 'Toggle any terminal by name',
  })

  api.nvim_create_user_command('Run', function(opts)
    local cmd = opts.args

    -- Validate that the executable (first token) is actually on PATH.
    local exe = cmd:match("^%S+")
    if vim.fn.executable(exe) ~= 1 then
      vim.notify(string.format("'%s' is not executable.", exe), vim.log.levels.ERROR)
      return
    end

    local term = terminal_manager.get_terminal("runner")
    if not term then
      term = terminal_manager.create_terminal("runner", { title = "Runner" })
    end

    -- Update the visible window title to reflect the executable being run
    -- without mutating config.title, which is the terminal's persistent label.
    term._display_title = "Run: " .. exe
    term:open(cmd)
  end, {
    nargs    = '+',
    complete = 'shellcmd',
    desc     = 'Run a command in a floating terminal',
  })

  if not user_commands or type(user_commands) ~= 'table' then
    return
  end

  for _, cmd_config in ipairs(user_commands) do
    local cmd_name  = cmd_config.name
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
        vim.notify(
          string.format("Terminal '%s' not found for command '%s'", term_name, cmd_name),
          vim.log.levels.ERROR
        )
      end
    end, {
      desc = cmd_config.desc or string.format("Toggle the '%s' terminal", term_name),
    })

    ::continue::
  end
end

return M
