local execute = require("runner.process").execute
local api, fn = vim.api, vim.fn

local M = {}

local current_buffer_hash = nil
local current_buffer_changedtick = nil

local function get_buffer_hash()
  local changedtick = api.nvim_buf_get_changedtick(0)

  if current_buffer_hash and current_buffer_changedtick == changedtick then
    return current_buffer_hash
  end

  local lines = api.nvim_buf_get_lines(0, 0, -1, true)
  current_buffer_hash = fn.sha256(table.concat(lines, "\n"))
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
  vim.cmd("ToggleTerm")
  local job_id = api.nvim_buf_get_var(api.nvim_get_current_buf(), "terminal_job_id")
  vim.defer_fn(function()
    fn.chansend(job_id, cmd .. "\n")
  end, 75)
end

return M
