-- init.lua - Main plugin entry point
local M = {}

-- Language types
local TYPES = {
  COMPILED = "compiled",
  INTERPRETED = "interpreted",
  ASSEMBLED = "assembled",
  LINKED = "linked"
}

-- Default configurations
local DEFAULTS = {
  keymaps = {
    { key = "<leader>rr", action = "run", desc = "Run file" },
    { key = "<leader>rc", action = "compile", desc = "Compile file" },
    { key = "<leader>ra", action = "set_args", desc = "Set arguments" },
    { key = "<leader>ri", action = "info", desc = "Show info" },
    { key = "<leader>rd", action = "add_data_file", desc = "Add data file" },
    { key = "<leader>rx", action = "remove_data_file", desc = "Remove data file" },
    { key = "<leader>rq", action = "quickfix", desc = "Show problems" },
  },

  languages = {
    c = {
      type = TYPES.COMPILED,
      compiler = "gcc",
      flags = { "-std=c23", "-O2" },
      output_dir = "/tmp/"
    },
    cpp = {
      type = TYPES.COMPILED,
      compiler = "g++",
      flags = { "-std=c++20", "-O2" },
      output_dir = "/tmp/"
    },
    python = {
      type = TYPES.INTERPRETED,
      runner = "python3"
    },
    lua = {
      type = TYPES.INTERPRETED,
      runner = "lua"
    }
  }
}

-- Plugin state
local state = {
  config = {},
  args = nil,
  data_file = nil,
  hash_cache = {} -- Store file hashes to detect changes
}

-- Utility functions
local function get_current_file()
  return vim.api.nvim_buf_get_name(0)
end

local function get_filetype()
  return vim.api.nvim_get_option_value("filetype", { buf = 0 })
end

local function get_basename(file)
  return vim.fn.fnamemodify(file, ":t:r")
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO)
end

-- Get hash of current buffer content
local function get_buffer_hash()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local content = table.concat(lines, "\n")
  return vim.fn.sha256(content)
end

-- Check if recompilation is needed
local function needs_compilation()
  local current_hash = get_buffer_hash()
  local cached_hash = state.hash_cache.compile

  if cached_hash == current_hash then
    notify("Source unchanged, skipping compilation", vim.log.levels.WARN)
    return false
  end

  return true, current_hash
end

-- Execute command synchronously
local function execute(cmd_table)
  local result = { code = -1, stderr = "" }

  if not cmd_table or not cmd_table.cmd then
    result.stderr = "Invalid command"
    return result
  end

  local handle = vim.system(cmd_table.cmd, {
    timeout = 30000,
    text = true
  })

  local output = handle:wait()
  result.code = output.code
  result.stderr = output.stderr or ""

  return result
end

-- Core actions
local actions = {}

function actions.set_args()
  vim.ui.input({
    prompt = "Enter arguments: ",
    default = state.args or ""
  }, function(args)
    state.args = args ~= "" and args or nil
    notify(state.args and "Arguments set" or "Arguments cleared")
  end)
end

function actions.info()
  local file = get_current_file()
  local config = state.config
  local lines = {
    "File: " .. vim.fn.fnamemodify(file, ':t'),
    "Type: " .. get_filetype(),
    "Language: " .. config.type,
  }

  if config.compiler then
    table.insert(lines, "Compiler: " .. config.compiler)
    table.insert(lines, "Flags: " .. table.concat(config.flags or {}, " "))
  end

  if config.runner then
    table.insert(lines, "Runner: " .. config.runner)
  end

  table.insert(lines, "Arguments: " .. (state.args or "None"))
  table.insert(lines, "Data file: " .. (state.data_file or "None"))

  -- Show in floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.min(60, vim.o.columns - 10),
    height = #lines + 2,
    row = math.floor((vim.o.lines - #lines) / 2),
    col = math.floor((vim.o.columns - 60) / 2),
    style = "minimal",
    border = "rounded",
    title = " Build Info ",
  })

  vim.keymap.set("n", "q", vim.cmd.close, { buffer = buf, silent = true })
end

function actions.compile()
  local config = state.config
  if config.type ~= TYPES.COMPILED then
    return true -- No compilation needed
  end

  -- Check if compilation is needed
  local should_compile, current_hash = needs_compilation()
  if not should_compile then
    return true -- Use existing executable
  end

  vim.cmd("silent! update")

  local file = get_current_file()
  local basename = get_basename(file)
  local exe_file = config.output_dir .. basename

  local cmd = {
    config.compiler,
    unpack(config.flags or {}),
    "-o", exe_file,
    file
  }

  local result = execute({ cmd = cmd })

  if result.code == 0 then
    notify("Compilation successful")
    state.exe_file = exe_file
    state.hash_cache.compile = current_hash -- Cache the hash on success
    return true
  else
    vim.diagnostic.set(vim.api.nvim_create_namespace("runner"), 0, {}, {})
    if result.stderr ~= "" then
      notify("Compilation failed: " .. result.stderr, vim.log.levels.ERROR)
    end
    return false
  end
end

function actions.run()
  -- Check for errors first
  local errors = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
  if #errors > 0 then
    actions.quickfix()
    return
  end

  local config = state.config

  if config.type == TYPES.COMPILED then
    if not actions.compile() then
      return
    end

    local cmd = { state.exe_file }
    if state.args then
      vim.list_extend(cmd, vim.split(state.args, " "))
    end

    actions.run_in_terminal(table.concat(cmd, " "))
  elseif config.type == TYPES.INTERPRETED then
    vim.cmd("silent! update")

    local file = get_current_file()
    local cmd = config.runner .. " " .. file
    if state.args then
      cmd = cmd .. " " .. state.args
    end

    actions.run_in_terminal(cmd)
  end
end

function actions.run_in_terminal(cmd)
  if state.data_file then
    cmd = cmd .. " < " .. state.data_file
  end

  vim.cmd("ToggleTerm")

  -- Send command to terminal
  vim.defer_fn(function()
    local buf = vim.api.nvim_get_current_buf()
    local job_id = vim.api.nvim_buf_get_var(buf, "terminal_job_id")
    vim.fn.chansend(job_id, cmd .. "\n")
  end, 100)
end

function actions.add_data_file()
  local data_dir = vim.fs.find("dat", {
    upward = true,
    type = "directory",
    path = vim.fn.expand("%:p:h"),
    stop = vim.fn.expand("~")
  })[1]

  if not data_dir then
    notify("No 'dat' directory found", vim.log.levels.WARN)
    return
  end

  local files = {}
  for path, type in vim.fs.dir(data_dir) do
    if type == "file" then
      table.insert(files, vim.fs.joinpath(data_dir, path))
    end
  end

  if #files == 0 then
    notify("No files in data directory", vim.log.levels.WARN)
    return
  end

  table.sort(files)

  vim.ui.select(files, {
    prompt = "Current: " .. (state.data_file and vim.fn.fnamemodify(state.data_file, ':t') or "None"),
    format_item = function(item)
      return vim.fn.fnamemodify(item, ':t')
    end
  }, function(choice)
    if choice then
      state.data_file = choice
      notify("Data file set: " .. vim.fn.fnamemodify(choice, ':t'))
    end
  end)
end

function actions.remove_data_file()
  if not state.data_file then
    notify("No data file set", vim.log.levels.WARN)
    return
  end

  vim.ui.select({ "Yes", "No" }, {
    prompt = "Remove data file (" .. vim.fn.fnamemodify(state.data_file, ':t') .. ")?"
  }, function(choice)
    if choice == "Yes" then
      state.data_file = nil
      notify("Data file removed")
    end
  end)
end

function actions.quickfix()
  local diagnostics = vim.diagnostic.get()
  if #diagnostics == 0 then
    notify("No problems found")
    return
  end

  local items = vim.diagnostic.toqflist(diagnostics)
  vim.fn.setqflist({}, ' ', { title = "Problems", items = items })
  vim.cmd("copen " .. math.min(#items + 2, 10))
end

-- Setup function
function M.setup(opts)
  opts = opts or {}

  local ft = get_filetype()
  local lang_config = DEFAULTS.languages[ft]

  if not lang_config then
    notify("Unsupported filetype: " .. ft, vim.log.levels.WARN)
    return
  end

  -- Merge user config
  state.config = vim.tbl_deep_extend("force", lang_config, opts.languages and opts.languages[ft] or {})

  -- Create commands
  local commands = {
    { "RunnerRun", actions.run, "Run file" },
    { "RunnerSetArgs", actions.set_args, "Set arguments" },
    { "RunnerInfo", actions.info, "Show build info" },
    { "RunnerAddDataFile", actions.add_data_file, "Add data file" },
    { "RunnerRemoveDataFile", actions.remove_data_file, "Remove data file" },
    { "RunnerProblems", actions.quickfix, "Show problems" },
  }

  if state.config.type == TYPES.COMPILED then
    table.insert(commands, { "RunnerCompile", actions.compile, "Compile file" })
  end

  -- Register commands
  for _, cmd in ipairs(commands) do
    vim.api.nvim_create_user_command(cmd[1], cmd[2], { desc = cmd[3] })
  end

  -- Register keymaps
  local keymaps = vim.tbl_deep_extend("force", DEFAULTS.keymaps, opts.keymaps or {})
  for _, map in ipairs(keymaps) do
    if actions[map.action] then
      vim.keymap.set(map.mode or "n", map.key, actions[map.action], {
        buffer = 0,
        desc = map.desc
      })
    end
  end
end

return M
