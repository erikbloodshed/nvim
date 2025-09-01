local M = {}

M.setup = function(cfg)
  local ft = vim.bo.filetype
  local config = require("quickrun.config").filetype[ft]

  if not config then
    vim.notify("Unsupported filetype")
    return
  end

  local user_config = cfg and cfg.filetype[ft]
  if user_config then
    config = vim.tbl_extend("force", config, user_config)
  end

  if config.execution_model == "compiled" then
  elseif config.execution_model == "assembled" then
  elseif config.execution_model == "interpreted" then
  else
  end
end

return M
