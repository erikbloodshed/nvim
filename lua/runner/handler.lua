local M = {}

M.translate = function(command)
  local result = vim.system(command):wait()

  if result.code == 0 then
    vim.notify(string.format("Compilation successful with exit code %s.", result.code), vim.log.levels.INFO)
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
