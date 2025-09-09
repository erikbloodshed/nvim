local api, fn, uv = vim.api, vim.fn, vim.uv
local set, notify, log = api.nvim_set_option_value, vim.notify, vim.log.levels
local M = {}

local find_upward = function(name, ftype)
  if name then
    local path = vim.fs.find(name, {
      upward = true,
      type = ftype,
      path = fn.expand("%:p:h"),
      stop = fn.expand("~")
    })[1]
    return path
  end
  return nil
end

M.get_response_file = function(fname)
  local path = find_upward(fname, "file")
  if path then
    return { "@" .. path }
  end

  return nil
end

M.get_data_path = function(dirname)
  return find_upward(dirname, "directory")
end


M.get_files = function(dir)
  if not dir or dir == "" then
    return {}
  end

  local stat = uv.fs_stat(dir)
  if not stat or stat.type ~= "directory" then
    return {}
  end

  local files = {}
  local iter = vim.fs.dir(dir, {})
  if not iter then
    return {}
  end

  for path, entry_type in iter do
    if entry_type == "file" then
      table.insert(files, vim.fs.joinpath(dir, path))
    end
  end

  table.sort(files, function(a, b)
    return string.lower(a) < string.lower(b)
  end)

  return files
end

M.open = function(title, lines, ft)
  local max_length = 0
  local cols = vim.o.columns
  local rows = vim.o.lines
  local width = math.floor(cols * 0.6)
  local height = math.floor(rows * 0.6)

  if ft == "text" then
    for _, line in ipairs(lines) do
      max_length = math.max(max_length, #line)
    end

    width = max_length
    height = #lines
  end

  local buf = api.nvim_create_buf(false, true)

  api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = (rows - height) / 2 - 1,
    col = (cols - width) / 2,
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

M.get_date_modified = function(f_path)
  local file_stats = uv.fs_stat(f_path)
  if file_stats then
    return os.date("%Y-%B-%d %H:%M:%S", file_stats.mtime.sec)
  else
    return "Unable to retrieve file modified time."
  end
end

M.read_file = function(f_path)
  local f = io.open(f_path, "r")

  if not f then return nil, "Could not open file: " .. f_path end
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
    require("xrun.diagnostics").open_quickfixlist()
    return true
  end
  return false
end

return M
