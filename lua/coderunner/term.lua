-- lua/runner/term.lua
local M = {}
local log = vim.notify

--- Sends a command string to a new Neovim terminal.
-- @param cmd_table table A list of command arguments to be joined and executed.
-- @param delay_ms integer The delay in milliseconds before sending the command.
function M.send_command(cmd_table, delay_ms)
    -- Open a new terminal window. Consider vim.fn.termopen() for more control if needed.
    vim.cmd.terminal() -- Make it a terminal
    vim.defer_fn(function()
        local bufnr = vim.api.nvim_get_current_buf()
        -- Ensure the current buffer is indeed a terminal buffer
        if vim.bo[bufnr].buftype ~= "terminal" then
            log("Failed to send command: Current buffer is not a terminal.", vim.log.levels.WARN)
            return
        end

        local term_job_id = vim.b[bufnr].terminal_job_id
        if term_job_id and term_job_id > 0 then -- Ensure job_id is valid
            local cmd_str = table.concat(cmd_table, " ")
            vim.api.nvim_chan_send(term_job_id, cmd_str .. "\n") -- '\n' executes the command
        else
            log("Could not get terminal job ID. Command not sent. The terminal might not have initialized correctly.", vim.log.levels.WARN)
        end
    end, delay_ms)
end

return M
