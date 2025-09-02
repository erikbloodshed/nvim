local M = {}

M.config = {}

M.setup = function(cfg)
  local ft = vim.bo.filetype
  M.config = require("quickrun.config").filetype[ft]

  if not M.config then
    vim.notify("Unsupported filetype")
    return
  end

  local user_config = cfg and cfg.filetype[ft]
  if user_config then
    M.config = vim.tbl_extend("force", M.config, user_config)
  end

  local run_command = nil
  if M.config.execution_model == "compiled" then
    run_command = function()
    end
  elseif M.config.execution_model == "assembled" then
  elseif M.config.execution_model == "interpreted" then
  else
  end
end

return M
