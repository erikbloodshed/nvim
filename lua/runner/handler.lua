local execute = require("runner.process").execute

local M = {}

M.translate = function(state, key, command)
  local buffer_hash = state:get_buffer_hash()

  if state:get_hash(key) == buffer_hash then
    vim.notify("Source code is already processed for " .. key .. ".", vim.log.levels.WARN)
    return true
  end

  local result = execute(command)

  if result.code == 0 then
    state:set_hash(key, buffer_hash)
    local action_name = key:sub(1, 1):upper() .. key:sub(2)
    vim.notify(action_name .. " successful with exit code " .. result.code .. ".",
      vim.log.levels.INFO)
    return true
  else
    if result.stderr and result.stderr ~= "" then
      vim.notify(result.stderr, vim.log.levels.ERROR)
    end
    return false
  end
end

M.run = function(cmd)
  vim.cmd("ToggleTerm")
  local job_id = vim.bo.channel
  vim.defer_fn(function()
    vim.fn.chansend(job_id, cmd .. "\n")
  end, 75)
end

return M
