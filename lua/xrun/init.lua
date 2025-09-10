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
    map("n", m.key, actions[m.action], { buffer = 0, noremap = true, desc = m.desc })
  end

  -- Autocommand for updating dependencies on buffer write
  if config.type == "compiled" then
    vim.api.nvim_create_autocmd("BufWritePost", {
      buffer = 0,
      callback = function()
        state:update_dependencies()
      end,
    })
    -- Watch dependency files for changes
    for _, dep in ipairs(state.dependencies) do
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = dep,
        callback = function()
          state:invalidate_build_cache()
        end,
      })
    end
  end
end

return M
