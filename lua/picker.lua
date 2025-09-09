local api = vim.api
local fn = vim.fn

-- Fuzzy matching function
local function fuzzy_match(str, pattern)
  local score = 0
  local str_lower = str:lower()
  local pattern_lower = pattern:lower()
  local str_idx, pat_idx = 1, 1

  while str_idx <= #str_lower and pat_idx <= #pattern_lower do
    if str_lower:sub(str_idx, str_idx) == pattern_lower:sub(pat_idx, pat_idx) then
      score = score + 1
      pat_idx = pat_idx + 1
    else
      score = score - 0.1
    end
    str_idx = str_idx + 1
  end

  if pat_idx <= #pattern_lower then
    score = score - (#pattern_lower - pat_idx + 1)
  end

  return score
end

-- Get all entries recursively (files and directories), ignoring dotfiles
local function get_all_entries(dir)
  local entries = {}
  local function scan_dir(current_dir)
    local items = fn.readdir(current_dir)
    if not items then return end
    for _, item in ipairs(items) do
      if item ~= '.' and item ~= '..' and not item:match('^%.') then
        local path = current_dir .. '/' .. item
        local rel_path = path:sub(#dir + 2)
        if fn.isdirectory(path) == 1 then
          table.insert(entries, rel_path .. '/')
          scan_dir(path)
        else
          table.insert(entries, rel_path)
        end
      end
    end
  end
  scan_dir(dir)
  table.insert(entries, 1, '..')
  return entries
end

-- Create a file picker with fuzzy finder
local function file_picker()
  local current_dir = fn.getcwd()
  local all_entries = get_all_entries(current_dir)
  local filtered_entries = all_entries
  local search_term = ""

  -- Create buffers
  local buf = api.nvim_create_buf(false, true)
  local prompt_buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  api.nvim_buf_set_option(prompt_buf, 'buftype', 'prompt')
  api.nvim_buf_set_lines(buf, 0, -1, false, filtered_entries)

  -- Calculate window sizes safely
  local function calculate_width(entries)
    if #entries == 0 then return 30 end
    local max_len = 0
    for _, entry in ipairs(entries) do
      max_len = math.max(max_len, string.len(entry))
    end
    return math.min(50, max_len)
  end

  local width = calculate_width(filtered_entries)
  local height = math.min(10, math.max(1, #filtered_entries))
  local row = math.floor((vim.o.lines - height - 3) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create floating windows
  local win = api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = width,
    height = height,
    row = row + 3,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  local prompt_win = api.nvim_open_win(prompt_buf, true, {
    relative = 'editor',
    width = width,
    height = 1,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  -- Set up prompt
  fn.prompt_setprompt(prompt_buf, "> ")

  -- Update file list based on search term
  local function update_file_list()
    if search_term == "" then
      filtered_entries = all_entries
    else
      local scored_entries = {}
      for _, entry in ipairs(all_entries) do
        local score = fuzzy_match(entry, search_term)
        if score > 0 then
          table.insert(scored_entries, { entry = entry, score = score })
        end
      end
      table.sort(scored_entries, function(a, b) return a.score > b.score end)
      filtered_entries = vim.tbl_map(function(item) return item.entry end, scored_entries)
    end

    api.nvim_buf_set_option(buf, 'modifiable', true)
    api.nvim_buf_set_lines(buf, 0, -1, false, filtered_entries)
    api.nvim_buf_set_option(buf, 'modifiable', false)

    if #filtered_entries > 0 then
      api.nvim_win_set_cursor(win, { 1, 0 })
    end

    -- Update window sizes
    width = calculate_width(filtered_entries)
    height = math.min(10, math.max(1, #filtered_entries))
    row = math.floor((vim.o.lines - height - 3) / 2)
    col = math.floor((vim.o.columns - width) / 2)
    api.nvim_win_set_config(win, {
      relative = 'editor',
      width = width,
      height = height,
      row = row + 3,
      col = col,
    })
    api.nvim_win_set_config(prompt_win, {
      relative = 'editor',
      width = width,
      row = row,
      col = col,
    })
  end

  -- Autocmd for live updating on text change
  local autocmd_id = api.nvim_create_autocmd("TextChangedI", {
    buffer = prompt_buf,
    callback = function()
      local text = api.nvim_buf_get_lines(prompt_buf, 0, 1, false)[1] or ""
      search_term = text:sub(3) -- Remove "> "
      update_file_list()
    end,
  })

  -- Keymaps for main window
  api.nvim_buf_set_keymap(buf, 'n', '<CR>', '', {
    callback = function()
      if #filtered_entries == 0 then return end
      local line = api.nvim_get_current_line()
      local clean_line = line:gsub('/$', '')
      local path = fn.fnamemodify(current_dir .. '/' .. clean_line, ':p')
      if line == '..' or fn.isdirectory(path) == 1 then
        current_dir = path
        vim.cmd('cd ' .. fn.fnameescape(current_dir))
        all_entries = get_all_entries(current_dir)
        search_term = ""
        api.nvim_buf_set_lines(prompt_buf, 0, -1, false, { "> " })
        update_file_list()
      else
        api.nvim_win_close(win, true)
        api.nvim_win_close(prompt_win, true)
        api.nvim_del_autocmd(autocmd_id)
        vim.cmd('edit ' .. fn.fnameescape(path))
      end
    end,
    noremap = true,
    silent = true,
  })

  api.nvim_buf_set_keymap(buf, 'n', 'q', '', {
    callback = function()
      api.nvim_win_close(win, true)
      api.nvim_win_close(prompt_win, true)
      api.nvim_del_autocmd(autocmd_id)
    end,
    noremap = true,
    silent = true,
  })

  -- Keymaps for prompt window
  api.nvim_buf_set_keymap(prompt_buf, 'i', '<CR>', '', {
    callback = function()
      if #filtered_entries == 0 then return end
      local cur_row = api.nvim_win_get_cursor(win)[1]
      local line = filtered_entries[cur_row]
      local clean_line = line:gsub('/$', '')
      local path = fn.fnamemodify(current_dir .. '/' .. clean_line, ':p')
      if line == '..' or fn.isdirectory(path) == 1 then
        current_dir = path
        vim.cmd('cd ' .. fn.fnameescape(current_dir))
        all_entries = get_all_entries(current_dir)
        search_term = ""
        api.nvim_buf_set_lines(prompt_buf, 0, -1, false, { "> " })
        update_file_list()
      else
        api.nvim_win_close(win, true)
        api.nvim_win_close(prompt_win, true)
        api.nvim_del_autocmd(autocmd_id)
        vim.cmd('edit ' .. fn.fnameescape(path))
      end
    end,
    noremap = true,
    silent = true,
  })

  api.nvim_buf_set_keymap(prompt_buf, 'i', '<Esc>', '', {
    callback = function()
      api.nvim_win_close(win, true)
      api.nvim_win_close(prompt_win, true)
      api.nvim_del_autocmd(autocmd_id)
    end,
    noremap = true,
    silent = true,
  })

  api.nvim_buf_set_keymap(prompt_buf, 'i', '<C-n>', '', {
    callback = function()
      local cur = api.nvim_win_get_cursor(win)[1]
      if cur < #filtered_entries then
        api.nvim_win_set_cursor(win, { cur + 1, 0 })
      end
    end,
    noremap = true,
    silent = true,
  })

  api.nvim_buf_set_keymap(prompt_buf, 'i', '<C-p>', '', {
    callback = function()
      local cur = api.nvim_win_get_cursor(win)[1]
      if cur > 1 then
        api.nvim_win_set_cursor(win, { cur - 1, 0 })
      end
    end,
    noremap = true,
    silent = true,
  })

  -- Highlight current line in main window
  api.nvim_win_set_option(win, 'cursorline', true)

  -- Start in insert mode for prompt
  vim.cmd('startinsert')
end

vim.api.nvim_create_user_command('FilePicker', file_picker, {})
