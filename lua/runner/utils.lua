local api, fn, uv = vim.api, vim.fn, vim.uv
local set, notify, log = api.nvim_set_option_value, vim.notify, vim.log.levels
local M = {}

local find_upward = function(name, find_type)
  if name then
    local path = vim.fs.find(name, {
      upward = true,
      type = find_type,
      path = fn.expand("%:p:h"),
      stop = fn.expand("~")
    })[1]
    return path
  end
  return nil
end

M.get_response_file = function(filename)
  local path = find_upward(filename, "file")
  if path then
    return { "@" .. path }
  end

  return nil
end

M.get_data_path = function(dirname)
  return find_upward(dirname, "directory")
end


M.scan_dir = function(dir)
  if not dir or dir == "" then
    vim.notify("Invalid directory path", log.WARN)
    return {}
  end

  local stat = uv.fs_stat(dir)
  if not stat or stat.type ~= "directory" then
    vim.notify("Directory not found or is not a directory: " .. dir, log.WARN)
    return {}
  end

  local result = {}

  local iter, err = vim.fs.dir(dir, {})
  if not iter then
    local msg = "Failed to scan directory: " .. dir
    if err then
      msg = msg .. " (" .. err .. ")"
    end
    vim.notify(msg, log.ERROR)
    return {}
  end

  local result_count = 0
  for path, entry_type in iter do
    if entry_type == "file" then
      local full_path = vim.fs.joinpath(dir, path)
      result_count = result_count + 1
      result[result_count] = full_path
    end
  end

  if result_count > 0 then
    if result_count > 1000 then
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
      table.sort(result, function(a, b)
        return string.lower(a) < string.lower(b)
      end)
    end
  end

  return result
end

M.open = function(title, lines, ft)
  local max_line_length = 0

  for _, line in ipairs(lines) do
    max_line_length = math.max(max_line_length, #line)
  end

  local width = math.min(max_line_length + 4, math.floor(vim.o.columns * 0.8))
  local height = math.min(#lines, math.floor(vim.o.lines * 0.8))
  local buf = api.nvim_create_buf(false, true)

  api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  api.nvim_open_win(buf, true, {
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

  set("buftype", "nofile", { scope = "local", buf = buf })
  set("bufhidden", "wipe", { scope = "local", buf = buf })
  set("swapfile", false, { scope = "local", buf = buf })
  set("filetype", ft, { scope = "local", buf = buf })
  set("modifiable", false, { scope = "local", buf = buf })

  vim.keymap.set("n", "q", vim.cmd.close, { buffer = buf, noremap = true, nowait = true, silent = true })

  return buf
end

M.get_date_modified = function(filepath)
  local file_stats = uv.fs_stat(filepath)
  if file_stats then
    return os.date("%Y-%B-%d %H:%M:%S", file_stats.mtime.sec)
  else
    return "Unable to retrieve file modified time."
  end
end

M.read_file = function(filepath)
  local f = io.open(filepath, "r")

  if not f then return nil, "Could not open file: " .. filepath end
  local content = {}
  for line in f:lines() do table.insert(content, line) end
  f:close()

  return content
end

M.translate = function(c)
  local r = vim.system(c):wait()

  if r.code == 0 then
    notify(string.format("Compilation successful with exit code %s.", r.code), log.INFO)
    return true
  end

  if r.stderr and r.stderr ~= "" then
    notify(r.stderr, log.ERROR)
  end

  return false
end

M.run = function(c)
  vim.cmd("ToggleTerm")
  local job_id = vim.bo.channel
  vim.defer_fn(function()
    fn.chansend(job_id, c .. "\n")
  end, 75)
end

M.has_errors = function()
  if #vim.diagnostic.count(0, { severity = { vim.diagnostic.severity.ERROR } }) > 0 then
    require("runner.diagnostics").open_quickfixlist()
    return true
  end
  return false
end



return M
