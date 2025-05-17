local api = vim.api
local keymap = vim.keymap.set

---@diagnostic disable: duplicate-set-field
vim.ui.input = function(opts, on_confirm)
    opts = opts or {}

    local prompt = opts.prompt or "Input: "
    local default = opts.default or ""
    on_confirm = on_confirm or function() end

    local default_width = #default + 8
    local prompt_width = #prompt + 8
    local input_width = math.max(default_width, prompt_width)

    local default_win_config = {
        relative = "cursor",
        row = 1,
        col = 0,
        focusable = false,
        style = "minimal",
        border = "rounded",
        width = input_width,
        height = 1,
        title = prompt,
        noautocmd = true,
    }

    if prompt ~= "New Name: " then
        default_win_config.relative = "win"
        default_win_config.row = math.max(api.nvim_win_get_height(0) / 2 - 1, 0)
        default_win_config.col = math.max(api.nvim_win_get_width(0) / 2 - input_width / 2, 0)
    end

    local bufnr = api.nvim_create_buf(false, true)
    api.nvim_open_win(bufnr, true, default_win_config)
    api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, { default })

    vim.cmd("startinsert")
    api.nvim_win_set_cursor(0, { 1, #default + 1 })

    keymap({ "n", "i", "v" }, "<cr>", function()
        on_confirm(api.nvim_buf_get_lines(bufnr, 0, 1, false)[1])
        vim.cmd("stopinsert")
        vim.defer_fn(function() api.nvim_win_close(0, true) end, 5)
    end, { buffer = bufnr })

    keymap("n", "<esc>", function()
        on_confirm(nil)
        vim.cmd("stopinsert")
        vim.defer_fn(function() api.nvim_win_close(0, true) end, 5)
    end, { buffer = bufnr })

    keymap("n", "q", function()
        on_confirm(nil)
        vim.cmd("stopinsert")
        vim.defer_fn(function() api.nvim_win_close(0, true) end, 5)
    end, { buffer = bufnr })
end
