local M = {}

function M.setup(manager, usr_maps)
  if not usr_maps or type(usr_maps) ~= 'table' then
    return
  end

  for _, map_config in ipairs(usr_maps) do
    if not (map_config.lhs and map_config.terminal and map_config.action) then
      vim.notify("Term: Invalid keymap config. Requires 'lhs', 'terminal', and 'action'.",
        vim.log.levels.WARN)
      goto continue
    end

    local terminal = manager.get_terminal(map_config.terminal)
    if not terminal then
      vim.notify(
        string.format("Term: Terminal '%s' not found for keymap '%s'.", map_config.terminal, map_config.lhs),
        vim.log.levels.WARN)
      goto continue
    end

    local rhs
    if map_config.action == 'toggle' then
      rhs = function() terminal:toggle() end
    end

    vim.keymap.set(map_config.mode or 'n', map_config.lhs, rhs, {
      noremap = true,
      silent = true,
      desc = map_config.desc or
        string.format("%s '%s' terminal", map_config.action:gsub("^%l", string.upper), map_config.terminal)
    })

    ::continue::
  end
end

return M
