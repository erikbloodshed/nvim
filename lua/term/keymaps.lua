local M = {}

-- Maps a keymap action string to a function on the terminal instance.
-- Add entries here as new actions are introduced.
local action_handlers = {
  toggle = function(terminal) terminal:toggle() end,
  open   = function(terminal) terminal:open() end,
  hide   = function(terminal) terminal:hide() end,
}

function M.setup(manager, usr_maps)
  if not usr_maps or type(usr_maps) ~= 'table' then
    return
  end

  for _, map_config in ipairs(usr_maps) do
    if not (map_config.lhs and map_config.terminal and map_config.action) then
      vim.notify(
        "TermSwitch: Invalid keymap config. Requires 'lhs', 'terminal', and 'action'.",
        vim.log.levels.WARN
      )
      goto continue
    end

    local terminal = manager.get_terminal(map_config.terminal)
    if not terminal then
      vim.notify(
        string.format("TermSwitch: Terminal '%s' not found for keymap '%s'.", map_config.terminal, map_config.lhs),
        vim.log.levels.WARN
      )
      goto continue
    end

    local handler = action_handlers[map_config.action]
    if not handler then
      vim.notify(
        string.format("TermSwitch: Unknown action '%s' for keymap '%s'.", map_config.action, map_config.lhs),
        vim.log.levels.WARN
      )
      goto continue
    end

    vim.keymap.set(map_config.mode or 'n', map_config.lhs, function() handler(terminal) end, {
      noremap = true,
      silent  = true,
      desc    = map_config.desc
        or string.format("%s '%s' terminal", map_config.action:gsub("^%l", string.upper), map_config.terminal),
    })

    ::continue::
  end
end

return M
