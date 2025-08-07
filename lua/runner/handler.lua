-- In handler.lua
local fn = vim.fn
local api = vim.api
local execute = require("runner.process").execute

local get_buffer_hash = function()
  local lines = api.nvim_buf_get_lines(0, 0, -1, true)
  local content = table.concat(lines, "\n")
  return fn.sha256(content)
end

local M = {}

M.translate = function(value, key, command)
  -- No command provided (may happen with interpreted languages)
  if not command then
    return true
  end

  local buffer_hash = get_buffer_hash()

  if value[key] == buffer_hash then
    vim.notify("Source code is already processed for " .. key .. ".", vim.log.levels.WARN)
    return true
  end

  local result = execute(command)

  if result.code == 0 then
    value[key] = buffer_hash
    local action_name = key:sub(1, 1):upper() .. key:sub(2)
    vim.notify(action_name .. " successful with exit code " .. result.code .. ".",
      vim.log.levels.INFO)
    return true
  else
    if result.stderr ~= nil then
      vim.notify(result.stderr, vim.log.levels.ERROR)
    end
    return false
  end
end

M.run = function(cmd_str, args, datfile)
  if not cmd_str then
    vim.notify("No run command available for this language type", vim.log.levels.ERROR)
    return
  end

  local cmd = cmd_str

  if args then cmd = cmd .. " " .. args end
  if datfile then cmd = cmd .. " < " .. datfile end

  vim.cmd("ToggleTerm")

  local buf = api.nvim_get_current_buf()
  local job_id = api.nvim_buf_get_var(buf, "terminal_job_id")
  vim.defer_fn(function()
    vim.fn.chansend(job_id, cmd .. "\n")
  end, 75)
end

return M
