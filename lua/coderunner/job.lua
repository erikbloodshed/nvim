-- lua/runner/job.lua
local utils = require('coderunner.utils')
local log = vim.notify

local M = {}

--- Links object files if required by the runner settings.
-- @param runner_settings table Configuration for the current filetype's runner.
-- @param file_info table Information about the file being processed.
-- @param callback function Called with `true` for success, `false` for failure.
local function link_file(runner_settings, file_info, callback)
    if not runner_settings.needs_linking or not runner_settings.link then
        log("Linking not required or link command not defined.", vim.log.levels.DEBUG)
        callback(true) -- No linking needed, considered a success for this step
        return
    end

    local link_cmd = utils.replace_placeholders(runner_settings.link, file_info)
    log("Linking with command: " .. table.concat(link_cmd, " "), vim.log.levels.INFO)

    vim.system(link_cmd, { text = true }, function(obj)
        vim.schedule(function() -- Schedule to run on the main Neovim thread
            if obj.code == 0 then
                log("Linking successful!", vim.log.levels.INFO)
                callback(true)
            else
                local error_msg = "Linking failed for " .. file_info.filename .. "!"
                if obj.stderr and obj.stderr ~= "" then
                    error_msg = error_msg .. "\nStderr:\n" .. obj.stderr
                end
                if obj.stdout and obj.stdout ~= "" then -- Sometimes errors go to stdout
                    error_msg = error_msg .. "\nStdout:\n" .. obj.stdout
                end
                log(error_msg, vim.log.levels.ERROR)
                callback(false)
            end
        end)
    end)
end

--- Compiles the file if needed, then proceeds to link if compilation is successful.
-- @param runner_settings table Configuration for the current filetype's runner.
-- @param file_info table Information about the file being processed.
-- @param callback function Called with `true` for success, `false` for failure.
function M.compile_and_link(runner_settings, file_info, callback)
    if not runner_settings.needs_compilation or not runner_settings.compile then
        callback(true) -- No compilation needed, proceed as success
        return
    end

    local compile_cmd = utils.replace_placeholders(runner_settings.compile, file_info)

    vim.system(compile_cmd, { text = true }, function(obj)
        vim.schedule(function() -- Schedule to run on the main Neovim thread
            if obj.code == 0 then
                log("Compilation successful for " .. file_info.filename .. "!", vim.log.levels.INFO)
                if runner_settings.needs_linking then
                    link_file(runner_settings, file_info, callback)
                else
                    callback(true) -- Compilation successful, no linking needed
                end
            else
                local error_msg = "Compilation failed for " .. file_info.filename .. "!"
                if obj.stderr and obj.stderr ~= "" then
                    error_msg = error_msg .. "\nStderr:\n" .. obj.stderr
                end
                if obj.stdout and obj.stdout ~= "" then  -- Sometimes errors go to stdout
                    error_msg = error_msg .. "\nStdout:\n" .. obj.stdout
                end
                log(error_msg, vim.log.levels.ERROR)
                callback(false) -- Compilation failed
            end
        end)
    end)
end

return M
