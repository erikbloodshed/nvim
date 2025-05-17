local auto_close_group = vim.api.nvim_create_augroup("DiagnosticsAutoCloseOnBufLeave", { clear = true })

vim.api.nvim_create_autocmd("BufLeave", {
    group = auto_close_group,
    pattern = "*",                                                 -- Trigger on leaving any buffer
    callback = function()
        local qf_info = vim.fn.getqflist({ winid = 0, title = 1 }) -- title = 1 requests title info

        if qf_info.winid ~= 0 and qf_info.title == "Diagnostics" then
            if #vim.api.nvim_list_wins() > 1 then
                vim.cmd.cclose()
                vim.notify("Quickfix closed.", vim.log.levels.INFO)
            else
                vim.notify("Cannot close quickfix: It's the last window.", vim.log.levels.WARN)
            end
        end
    end,
})

return {
    open_quickfixlist = function()
        require("custom_ui.qf").setup({
            show_multiple_lines = false,
            max_filename_length = 30,
        })

        local diagnostics = vim.diagnostic.get() if vim.tbl_isempty(diagnostics) then
            vim.notify("No diagnostics in current buffer.", vim.log.levels.INFO)
            return
        end

        local items = vim.diagnostic.toqflist(diagnostics)

        vim.fn.setqflist({}, ' ', { title = "Diagnostics", items = items })
        local height = math.min(math.max(#items, 3), 10)

        vim.cmd("copen " .. height)
    end,
}
