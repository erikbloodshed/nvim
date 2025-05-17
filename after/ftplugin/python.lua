local py_file = vim.fn.expand("%:~"):gsub(" ", "\\ ")

vim.keymap.set({ "n" }, "<leader>rr", function()
    local diagnostics = vim.diagnostic.get(0, {
        severity = {
            vim.diagnostic.severity.ERROR,
            -- vim.diagnostic.severity.WARN,
        },
    })

    if next(diagnostics) ~= nil then
        return
    end

    vim.api.nvim_command("write")
    vim.cmd.terminal()
    vim.defer_fn(function()
        vim.api.nvim_input("python3 " .. py_file .. "<CR>")
    end, 75)
end, { buffer = true, noremap = true, nowait = true })
