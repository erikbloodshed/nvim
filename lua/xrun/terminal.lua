local api, fn = vim.api, vim.fn

local M = {}

local Terminal = {}
Terminal.__index = Terminal

function Terminal:new(opts)
  opts = opts or {}

  local obj = setmetatable({
    buf_id = nil,
    win_id = nil,
    job_id = nil,
    is_open = false,
    config = vim.tbl_deep_extend("force", {
      -- Window configuration
      size = 0.3,               -- Size as fraction of editor (0.0 to 1.0)
      direction = "horizontal", -- "horizontal", "vertical", "float"
      position = "bottom",      -- "top", "bottom", "left", "right" (for splits)

      -- Float window specific options
      float = {
        relative = "editor",
        border = "rounded",
        title = " Terminal ",
        title_pos = "center",
      },

      -- Terminal options
      shell = vim.o.shell,
      auto_close = true,      -- Close terminal when process exits
      start_in_insert = true, -- Start in insert mode when opened
      close_on_exit = true,   -- Close window when terminal job exits
    }, opts)
  }, Terminal)

  return obj
end

function Terminal:_create_buffer()
  if self.buf_id and api.nvim_buf_is_valid(self.buf_id) then
    return self.buf_id
  end

  self.buf_id = api.nvim_create_buf(false, true)

  -- Set buffer options
  api.nvim_set_option_value("bufhidden", "hide", { buf = self.buf_id })
  api.nvim_set_option_value("swapfile", false, { buf = self.buf_id })
  api.nvim_set_option_value("buflisted", false, { buf = self.buf_id })

  return self.buf_id
end

function Terminal:_create_window()
  local buf_id = self:_create_buffer()

  if self.config.direction == "float" then
    return self:_create_float_window(buf_id)
  else
    return self:_create_split_window(buf_id)
  end
end

function Terminal:_create_float_window(buf_id)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)

  local win_config = vim.tbl_deep_extend("force", {
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
  }, self.config.float)

  self.win_id = api.nvim_open_win(buf_id, true, win_config)
  return self.win_id
end

function Terminal:_create_split_window(buf_id)
  local cmd
  local size = math.floor((self.config.direction == "horizontal" and vim.o.lines or vim.o.columns) * self.config.size)

  if self.config.direction == "horizontal" then
    if self.config.position == "top" then
      cmd = string.format("topleft %dsplit", size)
    else
      cmd = string.format("botright %dsplit", size)
    end
  else -- vertical
    if self.config.position == "left" then
      cmd = string.format("topleft %dvsplit", size)
    else
      cmd = string.format("botright %dvsplit", size)
    end
  end

  vim.cmd(cmd)
  self.win_id = api.nvim_get_current_win()
  api.nvim_win_set_buf(self.win_id, buf_id)

  return self.win_id
end

function Terminal:_start_terminal()
  if not self.buf_id or not api.nvim_buf_is_valid(self.buf_id) then
    return false
  end

  -- Only start terminal if not already running
  if self.job_id and self:is_running() then
    return true
  end

  -- Set the buffer as current and start terminal
  local current_buf = api.nvim_get_current_buf()

  -- Switch to our terminal buffer
  api.nvim_set_current_buf(self.buf_id)

  -- Start terminal in the buffer
  if self.config.shell and self.config.shell ~= vim.o.shell then
    vim.cmd(string.format("terminal %s", self.config.shell))
  else
    vim.cmd("terminal")
  end

  -- Get the job ID from the buffer
  self.job_id = vim.b.terminal_job_id

  -- Restore previous buffer if it was different
  if current_buf ~= self.buf_id and api.nvim_buf_is_valid(current_buf) then
    api.nvim_set_current_buf(current_buf)
  end

  -- Set up auto-close behavior
  if self.config.close_on_exit then
    vim.api.nvim_create_autocmd("TermClose", {
      buffer = self.buf_id,
      once = true,
      callback = function()
        vim.schedule(function()
          local exit_code = vim.v.event.status
          if exit_code == 0 then
            self:close()
          end
          self.job_id = nil
        end)
      end
    })
  end

  return self.job_id ~= nil
end

function Terminal:open()
  if self.is_open and self.win_id and api.nvim_win_is_valid(self.win_id) then
    api.nvim_set_current_win(self.win_id)
    if self.config.start_in_insert then
      vim.cmd("startinsert")
    end
    return
  end

  self:_create_window()

  if self:_start_terminal() then
    self.is_open = true

    if self.config.start_in_insert then
      vim.cmd("startinsert")
    end

    -- Set window options
    api.nvim_set_option_value("number", false, { win = self.win_id })
    api.nvim_set_option_value("relativenumber", false, { win = self.win_id })
    api.nvim_set_option_value("signcolumn", "no", { win = self.win_id })
    api.nvim_set_option_value("foldcolumn", "0", { win = self.win_id })
    api.nvim_set_option_value("spell", false, { win = self.win_id })
  else
    vim.notify("Failed to start terminal", vim.log.levels.ERROR)
  end
end

function Terminal:close()
  if self.win_id and api.nvim_win_is_valid(self.win_id) then
    api.nvim_win_close(self.win_id, false)
  end

  self.win_id = nil
  self.is_open = false
end

function Terminal:toggle()
  if self.is_open and self.win_id and api.nvim_win_is_valid(self.win_id) then
    self:close()
  else
    self:open()
  end
end

function Terminal:execute(command)
  if not command or command == "" then
    return false
  end

  -- Open terminal if not open
  if not self.is_open then
    self:open()
  end

  -- Wait a bit for terminal to be ready, then send command
  vim.defer_fn(function()
    if self:is_running() then
      local cmd_with_newline = command .. "\n"
      fn.chansend(self.job_id, cmd_with_newline)
    else
      vim.notify("Terminal not ready for command execution", vim.log.levels.WARN)
    end
  end, 100)

  return true
end

function Terminal:send(data)
  if self:is_running() then
    fn.chansend(self.job_id, data)
    return true
  end
  return false
end

function Terminal:is_running()
  return self.job_id and fn.jobwait({ self.job_id }, 0)[1] == -1
end

function Terminal:get_job_id()
  return self.job_id
end

function Terminal:get_buffer_id()
  return self.buf_id
end

function Terminal:get_window_id()
  return self.win_id
end

function Terminal:destroy()
  self:close()

  if self.job_id then
    fn.jobstop(self.job_id)
    self.job_id = nil
  end

  if self.buf_id and api.nvim_buf_is_valid(self.buf_id) then
    api.nvim_buf_delete(self.buf_id, { force = true })
    self.buf_id = nil
  end
end

M.create_float = function()
  return Terminal:new({ direction = "float" })
end

return M
