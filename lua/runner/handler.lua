local execute = require("runner.process").execute

local M = {}

local current_buffer_hash = nil
local current_buffer_changedtick = nil

local function get_buffer_hash()
  local changedtick = vim.api.nvim_buf_get_changedtick(0)

  if current_buffer_hash and current_buffer_changedtick == changedtick then
    return current_buffer_hash
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local content = table.concat(lines, "\n")
  current_buffer_hash = vim.fn.sha256(content)
  current_buffer_changedtick = changedtick
  return current_buffer_hash
end

M.translate = function(state, key, command)
  local buffer_hash = get_buffer_hash()
  local cached_hash = state:get_hash(key)

  if cached_hash == buffer_hash then
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
  if not cmd then
    vim.notify("No run command available for this language type", vim.log.levels.ERROR)
    return
  end

  vim.cmd("ToggleTerm")

  local buf = vim.api.nvim_get_current_buf()
  local job_id = vim.api.nvim_buf_get_var(buf, "terminal_job_id")

  vim.defer_fn(function()
    vim.fn.chansend(job_id, cmd .. "\n")
  end, 75)
end

return M
