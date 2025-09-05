local M = {}

M.setup = function(cfg)
  local config = require("runner.config").init(cfg)

  if not config then
    vim.notify("No runner configuration for filetype: " ..
      vim.api.nvim_get_option_value("filetype", { buf = 0 }), vim.log.levels.WARN)
    return {}
  end

  local state = require("runner.state").init(config)
  local commands = require("runner.commands").create(state)
  local actions = require("runner.actions").create(state, commands)
  local keymaps = state.keymaps
  local map = vim.keymap.set

  for _, m in ipairs(keymaps) do
    if m.action and actions[m.action] then
      map(m.mode or "n", m.key, actions[m.action],
        { buffer = 0, noremap = true, desc = m.desc })
    end
  end
end

return M
