local cmd = vim.cmd
local fn = vim.fn
local api = vim.api

local get_buffer_hash = function()
    local lines = api.nvim_buf_get_lines(0, 0, -1, true)
    local content = table.concat(lines, "\n")
    return fn.sha256(content)
end

local M = {
    translate = function(value, key, command)
        local diagnostics = vim.diagnostic.count(0, { severity = { vim.diagnostic.severity.ERROR } })

        if #diagnostics == 0 then
            if api.nvim_get_option_value("modified", { buf = 0 }) then cmd("silent! write") end
            local buffer_hash = get_buffer_hash()

            if value[key] ~= buffer_hash then
                local result = require("codeforge.process").execute(command)

                if result.code == 0 then
                    value[key] = buffer_hash
                    vim.notify("Code compilation successful with exit code " .. result.code .. ".",
                        vim.log.levels.INFO)
                    return true
                else
                    if result.stderr ~= nil then
                        vim.notify(result.stderr, vim.log.levels.ERROR)
                    end
                    return false
                end
            end

            vim.notify("Source code is already compiled.", vim.log.levels.HINT)
            return true
        end

        require("diagnostics").open_quickfixlist()

        return false
    end,

    run = function(exe, args, datfile)
        local command = exe

        if args then
            command = command .. " " .. args
        end

        if datfile then
            command = command .. " < " .. datfile
        end

        vim.cmd.terminal()

        vim.defer_fn(function()
            local term_id = api.nvim_get_option_value("channel", { buf = 0 })
            if term_id then
                api.nvim_chan_send(term_id, command .. "\n")
            else
                vim.notify("Could not get terminal job ID to send command.", vim.log.levels.WARN)
            end
        end, 100)
    end
}

return M
