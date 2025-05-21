vim.api.nvim_create_autocmd("Filetype", {
    pattern = { "c", "cpp", "asm", "python", "lua" },
    callback = function(args)
        local run = function()
            local compiler = "g++"
            local src_file = vim.api.nvim_buf_get_name(args.buf)
            local src_basename = vim.fn.expand("%:t:r")
            local output = "/tmp/" .. src_basename

            -- Compile the C++ file
            vim.system({ compiler, "-o", output, src_file }, { text = true }, function(obj)
                -- Use vim.schedule to run UI operations in the main thread
                vim.schedule(function()
                    if obj.code == 0 then
                        vim.notify("Compilation successful!", vim.log.levels.INFO)

                        vim.cmd.terminal()

                        vim.defer_fn(function()
                            local bufnr = vim.api.nvim_get_current_buf()
                            local term_id = vim.b[bufnr].terminal_job_id

                            if term_id then
                                vim.api.nvim_chan_send(term_id, output .. "\n")
                            else
                                vim.notify("Could not get terminal job ID to send command.", vim.log.levels.WARN)
                            end
                        end, 200)
                    else
                        local error_msg = "Compilation failed!"
                        if obj.stderr and obj.stderr ~= "" then
                            error_msg = error_msg .. "\n" .. obj.stderr
                        end
                        vim.notify(error_msg, vim.log.levels.ERROR)
                    end
                end)
            end)
        end

        -- Set up the keymap
        vim.keymap.set("n", "<F5>",
            function() run() end, { buffer = args.buf, noremap = true, silent = true, desc = "Compile and run C++ file" })
    end,
})
