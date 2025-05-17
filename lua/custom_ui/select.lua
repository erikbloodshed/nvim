vim.api.nvim_set_hl(0, "CustomPickerSelection", { link = "Visual" })

local function close_picker(picker)
    if vim.api.nvim_win_is_valid(picker.win) then
        vim.api.nvim_win_close(picker.win, true)
    end
    if vim.api.nvim_buf_is_valid(picker.buf) then
        vim.api.nvim_buf_delete(picker.buf, { force = true })
    end
end

local function update_highlight(picker)
    vim.api.nvim_buf_clear_namespace(picker.buf, picker.ns, 0, -1)
    vim.api.nvim_buf_set_extmark(picker.buf, picker.ns, picker.selected - 1, 0, {
        line_hl_group = "CustomPickerSelection",
        end_col = 0,
        priority = 100
    })
end

local function move_picker(picker, delta)
    local count = #picker.items
    local new_idx = (picker.selected - 1 + delta) % count + 1
    picker.selected = new_idx
    vim.api.nvim_win_set_cursor(picker.win, { new_idx, 0 })
    update_highlight(picker)
end

local function pick(opts)
    local lines = {}
    local max_width = #opts.title
    for _, item in ipairs(opts.items) do
        local line = item.text or tostring(item)
        table.insert(lines, line)
    end

    local padding = 4
    local width = math.min(max_width + padding, vim.o.columns - 4)
    local height = math.min(#lines, 10)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = "rounded",
        style = "minimal",
        title = opts.title or "Select",
        title_pos = "center"
    })

    local picker = {
        buf = buf,
        win = win,
        ns = vim.api.nvim_create_namespace("custom_picker"),
        items = opts.items,
        selected = 1,
        actions = opts.actions or {},
        on_close = opts.on_close or function() end,
    }

    update_highlight(picker)
    vim.api.nvim_win_set_cursor(win, { 1, 0 })

    vim.keymap.set("n", "j", function() move_picker(picker, 1) end, { buffer = buf, nowait = true })
    vim.keymap.set("n", "k", function() move_picker(picker, -1) end, { buffer = buf, nowait = true })

    vim.keymap.set("n", "<CR>", function()
        if picker.actions.confirm then
            picker.actions.confirm(picker, picker.items[picker.selected])
        else
            close_picker(picker)
        end
    end, { buffer = buf })

    local function cancel()
        close_picker(picker)
        picker.on_close()
    end

    vim.keymap.set("n", "q", cancel, { buffer = buf })
    vim.keymap.set("n", "<Esc>", cancel, { buffer = buf })

    return picker
end

---@diagnostic disable: duplicate-set-field
vim.ui.select = function(items, opts, on_choice)
    opts = opts or {}

    local formatted_items = {}

    for idx, item in ipairs(items) do
        local text = (opts.format_item and opts.format_item(item)) or tostring(item)
        table.insert(formatted_items, {
            text = text,
            item = item,
            idx = idx,
        })
    end

    local completed = false

    pick({
        title = opts.prompt or "Select",
        items = formatted_items,
        actions = {
            confirm = function(picker, picked)
                if completed then return end
                completed = true
                close_picker(picker)
                vim.schedule(function()
                    on_choice(picked.item, picked.idx)
                end)
            end,
        },
        on_close = function()
            if completed then return end
            completed = true
            vim.schedule(function()
                on_choice(nil, nil)
            end)
        end,
    })
end
