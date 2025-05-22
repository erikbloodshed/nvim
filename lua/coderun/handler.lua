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
        vim.notify("Source code is already processed for " .. key .. ".", vim.log.levels.HINT)
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

    vim.cmd.terminal()

    vim.defer_fn(function()
        local term_id = api.nvim_get_option_value("channel", { buf = 0 })
        if term_id then
            api.nvim_chan_send(term_id, cmd .. "\n")
        else
            vim.notify("Could not get terminal job ID to send command.", vim.log.levels.WARN)
        end
    end, 100)
end

return M
