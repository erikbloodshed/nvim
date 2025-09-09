local M = {}

M.setup = function(cfg)
  local defaults = require("xrun.config")
  local ft = vim.bo.filetype
  local config = vim.tbl_deep_extend('force', defaults.filetype[ft], cfg.filetype[ft] or {})

  if not config then
    vim.notify("No runner configuration for filetype: " .. ft, vim.log.levels.WARN)
    return {}
  end

  local state = require("xrun.state").init(config)
  local commands = require("xrun.commands").create(state)
  local actions = require("xrun.actions").create(state, commands)
  local keymaps = vim.tbl_deep_extend('force', defaults.keymaps, cfg.keymaps or {})
  local map = vim.keymap.set

  for _, m in ipairs(keymaps) do
    if m.action and actions[m.action] then
      map(m.mode or "n", m.key, actions[m.action],
        { buffer = 0, noremap = true, desc = m.desc })
    end
  end
end

return M
