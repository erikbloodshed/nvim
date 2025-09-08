local M = {}

M.translate = function(key, command)
  local result = vim.system(command):wait()

  if result.code == 0 then
    local action_name = key:sub(1, 1):upper() .. key:sub(2)
    vim.notify(action_name .. " successful with exit code " .. result.code .. ".", vim.log.levels.INFO)
    return true
  end

  if result.stderr and result.stderr ~= "" then
    vim.notify(result.stderr, vim.log.levels.ERROR)
  end

  return false
end

M.run = function(cmd)
  vim.cmd("ToggleTerm")
  local job_id = vim.bo.channel
  vim.defer_fn(function()
    vim.fn.chansend(job_id, cmd .. "\n")
  end, 75)
end

return M
