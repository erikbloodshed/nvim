local uv = vim.uv

return {
    scan_dir = function(dir)
        -- Return empty on nil input
        if not dir or dir == "" then
            vim.notify("Invalid directory path", vim.log.levels.WARN)
            return {}
        end

        -- Fast path for directory existence check
        local stat = uv.fs_stat(dir)
        if not stat or stat.type ~= "directory" then
            vim.notify("Directory not found or is not a directory: " .. dir, vim.log.levels.WARN)
            return {}
        end

        -- Pre-allocate the result table with estimated capacity
        local result = {}

        -- Create the directory iterator
        local iter, err = vim.fs.dir(dir, {})
        if not iter then
            local msg = "Failed to scan directory: " .. dir
            if err then
                msg = msg .. " (" .. err .. ")"
            end
            vim.notify(msg, vim.log.levels.ERROR)
            return {}
        end

        -- Process the directory entries - optimize for the fast path
        local result_count = 0
        for path, entry_type in iter do
            -- We only care about files, not directories or symlinks
            if entry_type == "file" then
                -- Join paths more efficiently
                local full_path = vim.fs.joinpath(dir, path)
                result_count = result_count + 1
                result[result_count] = full_path
            end
        end

        -- Only sort if we have results
        if result_count > 0 then
            -- Optimize sorting for large directories
            if result_count > 1000 then
                -- For very large directories, use a more efficient sort algorithm
                -- Create a lookup table for lowercase strings to avoid repeated conversions
                local lower_cache = {}
                local function get_lower(str)
                    local lower = lower_cache[str]
                    if not lower then
                        lower = string.lower(str)
                        lower_cache[str] = lower
                    end
                    return lower
                end

                table.sort(result, function(a, b)
                    return get_lower(a) < get_lower(b)
                end)
            else
                -- For smaller directories, use the standard case-insensitive sort
                table.sort(result, function(a, b)
                    return string.lower(a) < string.lower(b)
                end)
            end
        end

        return result
    end,

    open = function(title, lines, ft)
        local max_line_length = 0

        for _, line in ipairs(lines) do
            max_line_length = math.max(max_line_length, #line)
        end

        local width = math.min(max_line_length + 4, math.floor(vim.o.columns * 0.8))
        local height = math.min(#lines, math.floor(vim.o.lines * 0.8))
        local buf = vim.api.nvim_create_buf(false, true)

        -- Fill buffer content
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

        -- Open floating window
        vim.api.nvim_open_win(buf, true, {
            relative = "editor",
            width = width,
            height = height,
            row = (vim.o.lines - height) / 2,
            col = (vim.o.columns - width) / 2,
            style = "minimal",
            border = "rounded",
            title = title,
            title_pos = "center",
        })

        vim.api.nvim_set_option_value("buftype", "nofile", {scope = "local", buf = buf})
        vim.api.nvim_set_option_value("bufhidden", "wipe", {scope = "local", buf = buf})
        vim.api.nvim_set_option_value("swapfile", false, {scope = "local", buf = buf})
        vim.api.nvim_set_option_value("filetype", ft, {scope = "local", buf = buf})
        vim.api.nvim_set_option_value("modifiable", false, {scope = "local", buf = buf})

        vim.keymap.set("n", "q", vim.cmd.close, { buffer = buf, noremap = true, nowait = true, silent = true })

        return buf
    end,

    get_data_path = function(filename)
        if filename then
            local path = vim.fs.find(filename, {
                upward = true,
                type = "directory",
                path = vim.fn.expand("%:p:h"),
                stop = vim.fn.expand("~"),
            })[1]
            return path
        end

        return nil
    end,

    get_date_modified = function(filepath)
        local file_stats = uv.fs_stat(filepath)
        if file_stats then
            return os.date("%Y-%B-%d %H:%M:%S", file_stats.mtime.sec)
        else
            return "Unable to retrieve file modified time."
        end
    end,

    merged_list = function(list1, list2)
        local list = {}

        local len1 = #list1
        for i = 1, len1 do list[i] = list1[i] end

        local len2 = #list2
        for i = 1, len2 do list[len1 + i] = list2[i] end

        return list
    end,

    read_file = function(filepath)
        local f = io.open(filepath, "r")

        if not f then return nil, "Could not open file: " .. filepath end
        local content = {}
        for line in f:lines() do table.insert(content, line) end
        f:close()

        return content
    end

}
