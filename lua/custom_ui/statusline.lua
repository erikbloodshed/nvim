local M = {}

-- Configuration
local config = {
  components = {
    mode = true,
    file_info = true,
    git_branch = true,
    diagnostics = true,
    lsp_status = true,
    encoding = false,
    position = true,
    percentage = true,
  },
  separators = {
    left = '',
    right = '',
    section = ' | ',
  },
  icons = {
    modified = '●',
    readonly = '',
    git = '',
    error = '',
    warn = '',
    info = '',
    hint = '',
    lsp = '󰒋',
  },

  center_filename = true, -- New option to control fixed centering
  exclude = {
    buftypes = { 'terminal', 'quickfix', 'help', 'nofile', 'prompt' },
    filetypes = {
      'NvimTree', 'neo-tree', 'aerial', 'Outline', 'packer', 'alpha', 'starter',
      'TelescopePrompt', 'TelescopeResults', 'TelescopePreview',
      'lazy', 'mason', 'lspinfo', 'null-ls-info',
      'checkhealth', 'help', 'man', 'qf', 'fugitive'
    },
    floating_windows = true,                            -- Disable statusline for floating windows
    small_windows = { min_height = 3, min_width = 20 }, -- Skip very small windows
  }
}

-- Mode configuration with colors
local modes = {
  n = { name = 'NORMAL', hl = 'StatusLineNormal' },
  i = { name = 'INSERT', hl = 'StatusLineInsert' },
  v = { name = 'VISUAL', hl = 'StatusLineVisual' },
  V = { name = 'V-LINE', hl = 'StatusLineVisual' },
  c = { name = 'COMMAND', hl = 'StatusLineCommand' },
  R = { name = 'REPLACE', hl = 'StatusLineReplace' },
  r = { name = 'REPLACE', hl = 'StatusLineReplace' },
  s = { name = 'SELECT', hl = 'StatusLineVisual' },
  S = { name = 'S-LINE', hl = 'StatusLineVisual' },
  t = { name = 'TERMINAL', hl = 'StatusLineTerminal' },
}

-- Highlight groups
local function setup_highlights()
  local highlights = {
    StatusLineNormal = { fg = '#89b4fa', bg = 'NONE', bold = true },
    StatusLineInsert = { fg = '#a6e3a1', bg = 'NONE', bold = true },
    StatusLineVisual = { fg = '#f38ba8', bg = 'NONE', bold = true },
    StatusLineCommand = { fg = '#f9e2af', bg = 'NONE', bold = true },
    StatusLineReplace = { fg = '#fab387', bg = 'NONE', bold = true },
    StatusLineTerminal = { fg = '#cba6f7', bg = 'NONE', bold = true },
    StatusLineFile = { fg = '#cdd6f4', bg = 'NONE' },
    StatusLineModified = { fg = '#ff6b6b', bg = 'NONE', bold = true },
    StatusLineReadonly = { fg = '#f38ba8', bg = 'NONE' },
    StatusLineGit = { fg = '#fab387', bg = 'NONE' },
    StatusLineInfo = { fg = '#a6adc8', bg = 'NONE' },
    StatusLineDiagError = { fg = '#f38ba8', bg = 'NONE' },
    StatusLineDiagWarn = { fg = '#f9e2af', bg = 'NONE' },
    StatusLineDiagInfo = { fg = '#89dceb', bg = 'NONE' },
    StatusLineDiagHint = { fg = '#94e2d5', bg = 'NONE' },
    StatusLineLSP = { fg = '#a6e3a1', bg = 'NONE' },
  }

  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

-- Cache for expensive operations
local cache = {
  mode = '',
  file_info = '',
  git_branch = '',
  diagnostics = '',
  lsp_status = '',
  encoding = '',
  position = '',
  percentage = '',
  last_update = 0,
}

-- Utility functions
local function is_cache_valid(component, ttl)
  ttl = ttl or 100 -- milliseconds
  local now = vim.loop.hrtime() / 1e6
  return (now - (cache['last_' .. component] or 0)) < ttl
end

local function update_cache(component, value)
  cache[component] = value
  cache['last_' .. component] = vim.loop.hrtime() / 1e6
end

-- Component builders
local components = {}

function components.mode()
  if not config.components.mode then return '' end

  local current_mode = vim.api.nvim_get_mode().mode
  local mode_info = modes[current_mode] or { name = 'UNKNOWN', hl = 'StatusLineNormal' }

  return string.format('%%#%s# %s %%*', mode_info.hl, mode_info.name)
end

function components.file_info()
  if not config.components.file_info then return '' end

  local parts = {}
  local filename = vim.fn.expand('%:t')

  if filename == '' then
    filename = '[No Name]'
  end

  -- File icon (if available)
  local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
  if has_devicons then
    local extension = vim.fn.expand('%:e')
    local icon = devicons.get_icon(filename, extension, { default = true })
    if icon then
      table.insert(parts, icon)
    end
  end

  -- Readonly indicator
  if vim.bo.readonly then
    table.insert(parts, '%#StatusLineReadonly#' .. config.icons.readonly .. '%*')
  end

  -- Filename with modification indicator
  if vim.bo.modified then
    table.insert(parts, '%#StatusLineModified#' .. filename .. ' ' .. config.icons.modified .. '%*')
  else
    table.insert(parts, '%#StatusLineFile#' .. filename .. '%*')
  end

  return table.concat(parts, ' ')
end

function components.git_branch()
  if not config.components.git_branch then return '' end
  if is_cache_valid('git_branch', 5000) then return cache.git_branch end

  -- Try vim-fugitive first
  local has_fugitive, fugitive = pcall(require, 'fugitive')
  if has_fugitive then
    local branch = vim.fn['FugitiveHead']()
    if branch and branch ~= '' then
      local result = string.format('%%#StatusLineGit#%s %s%%*', config.icons.git, branch)
      update_cache('git_branch', result)
      return result
    end
  end

  -- Fallback to git command
  local handle = io.popen('cd ' .. vim.fn.expand('%:p:h') .. ' 2>/dev/null && git branch --show-current 2>/dev/null')
  if handle then
    local branch = handle:read('*a'):gsub('%s+$', '')
    handle:close()
    if branch and branch ~= '' then
      local result = string.format('%%#StatusLineGit#%s %s%%*', config.icons.git, branch)
      update_cache('git_branch', result)
      return result
    end
  end

  update_cache('git_branch', '')
  return ''
end

function components.diagnostics()
  if not config.components.diagnostics then return '' end
  if is_cache_valid('diagnostics', 500) then return cache.diagnostics end

  local diagnostics = vim.diagnostic.get(0)
  local counts = { error = 0, warn = 0, info = 0, hint = 0 }

  for _, diagnostic in ipairs(diagnostics) do
    local severity = diagnostic.severity
    if severity == vim.diagnostic.severity.ERROR then
      counts.error = counts.error + 1
    elseif severity == vim.diagnostic.severity.WARN then
      counts.warn = counts.warn + 1
    elseif severity == vim.diagnostic.severity.INFO then
      counts.info = counts.info + 1
    elseif severity == vim.diagnostic.severity.HINT then
      counts.hint = counts.hint + 1
    end
  end

  local parts = {}
  if counts.error > 0 then
    table.insert(parts, string.format('%%#StatusLineDiagError#%s %d%%*', config.icons.error, counts.error))
  end
  if counts.warn > 0 then
    table.insert(parts, string.format('%%#StatusLineDiagWarn#%s %d%%*', config.icons.warn, counts.warn))
  end
  if counts.info > 0 then
    table.insert(parts, string.format('%%#StatusLineDiagInfo#%s %d%%*', config.icons.info, counts.info))
  end
  if counts.hint > 0 then
    table.insert(parts, string.format('%%#StatusLineDiagHint#%s %d%%*', config.icons.hint, counts.hint))
  end

  local result = table.concat(parts, ' ')
  update_cache('diagnostics', result)
  return result
end

function components.lsp_status()
  if not config.components.lsp_status then return '' end
  if is_cache_valid('lsp_status', 1000) then return cache.lsp_status end

  local clients = vim.lsp.get_active_clients({ bufnr = 0 })
  if #clients == 0 then
    update_cache('lsp_status', '')
    return ''
  end

  local client_names = {}
  for _, client in ipairs(clients) do
    table.insert(client_names, client.name)
  end

  local result = string.format('%%#StatusLineLSP#%s %s%%*', config.icons.lsp, table.concat(client_names, ', '))
  update_cache('lsp_status', result)
  return result
end

function components.encoding()
  if not config.components.encoding then return '' end
  if is_cache_valid('encoding', 10000) then return cache.encoding end

  local encoding = vim.bo.fileencoding
  if encoding == '' then encoding = vim.o.encoding end
  local result = '%#StatusLineInfo#' .. encoding:upper() .. '%*'
  update_cache('encoding', result)
  return result
end

function components.position()
  if not config.components.position then return '' end

  return string.format('%%#StatusLineInfo#Ln %d, Col %d%%*', vim.fn.line('.'), vim.fn.col('.'))
end

function components.percentage()
  if not config.components.percentage then return '' end

  local current_line = vim.fn.line('.')
  local total_lines = vim.fn.line('$')
  local percentage = math.floor((current_line / total_lines) * 100)

  return string.format('%%#StatusLineInfo#%d%%%%%%*', percentage)
end

-- Utility function to strip highlight groups and get display width
local function get_display_width(str)
  -- Remove highlight groups (%#...#, %*)
  local clean_str = str:gsub('%%#[^#]*#', ''):gsub('%%*', '')
  -- Handle other vim statusline format specifiers
  clean_str = clean_str:gsub('%%=', ''):gsub('%%<', '')
  return vim.fn.strdisplaywidth(clean_str)
end

-- Main statusline builder with fixed centered filename
function M.statusline()
  -- Get current window info for context
  local win_id = vim.api.nvim_get_current_win()
  local buf_id = vim.api.nvim_win_get_buf(win_id)

  local left_parts = {}
  local right_parts = {}

  -- Left side components
  table.insert(left_parts, components.mode())

  local git = components.git_branch()
  if git ~= '' then
    table.insert(left_parts, git)
  end

  -- Right side components
  local diagnostics = components.diagnostics()
  if diagnostics ~= '' then
    table.insert(right_parts, diagnostics)
  end

  local lsp = components.lsp_status()
  if lsp ~= '' then
    table.insert(right_parts, lsp)
  end

  if config.components.encoding then
    table.insert(right_parts, components.encoding())
  end

  table.insert(right_parts, components.position())

  if config.components.percentage then
    table.insert(right_parts, components.percentage())
  end

  -- Build left and right sections
  local left_section = table.concat(left_parts, ' ')
  local right_section = table.concat(right_parts, config.separators.section)
  local center_section = components.file_info()

  -- Use fixed centering if enabled
  if config.center_filename then
    -- Calculate display widths (excluding highlight codes)
    local left_width = get_display_width(left_section)
    local right_width = get_display_width(right_section)
    local center_width = get_display_width(center_section)

    -- Get current window width (not global)
    local win_width = vim.api.nvim_win_get_width(win_id)

    -- Calculate padding needed to center the filename
    local total_side_width = left_width + right_width
    local available_center = win_width - total_side_width

    -- If there's not enough space, fall back to simple layout
    if available_center < center_width + 4 then -- +4 for minimum padding
      return left_section .. '%=' .. center_section .. '%=' .. right_section
    end

    -- Calculate exact positioning for perfect centering
    local center_start = math.floor((win_width - center_width) / 2)
    local left_padding = center_start - left_width
    local right_padding = win_width - center_start - center_width - right_width

    -- Ensure minimum padding
    left_padding = math.max(left_padding, 1)
    right_padding = math.max(right_padding, 1)

    -- Build the statusline with precise positioning
    local statusline = left_section
    statusline = statusline .. string.rep(' ', left_padding)
    statusline = statusline .. center_section
    statusline = statusline .. string.rep(' ', right_padding)
    statusline = statusline .. right_section

    -- Handle any remaining space to prevent line wrapping
    local current_width = get_display_width(statusline)
    if current_width < win_width then
      statusline = statusline .. string.rep(' ', win_width - current_width)
    elseif current_width > win_width then
      -- Fallback if calculation is off
      return left_section .. '%=' .. center_section .. '%=' .. right_section
    end

    return statusline
  else
    -- Use standard vim statusline alignment
    return left_section .. '%=' .. center_section .. '%=' .. right_section
  end
end

-- Function to enable statusline for current window
function M.enable()
  local win_id = vim.api.nvim_get_current_win()
  vim.wo[win_id].statusline = '%!v:lua.require("custom_ui.statusline").statusline()'
end

-- Function to disable statusline for current window
function M.disable()
  local win_id = vim.api.nvim_get_current_win()
  vim.wo[win_id].statusline = ''
end

-- Function to refresh all statuslines
function M.refresh()
  refresh_all_statuslines()
end

-- Function to check if a window should have the statusline
local function should_have_statusline(win_id)
  -- Check if it's a floating window
  if config.exclude.floating_windows then
    local win_config = vim.api.nvim_win_get_config(win_id)
    if win_config.relative ~= '' then
      -- It's a floating window, don't add statusline
      return false
    end
  end

  local buf_id = vim.api.nvim_win_get_buf(win_id)
  local buf_type = vim.api.nvim_get_option_value('buftype', { buf = buf_id })
  local file_type = vim.api.nvim_get_option_value('filetype', { buf = buf_id })

  -- Skip configured buffer types
  for _, skip_type in ipairs(config.exclude.buftypes) do
    if buf_type == skip_type then return false end
  end

  -- Skip configured file types
  for _, skip_type in ipairs(config.exclude.filetypes) do
    if file_type == skip_type then return false end
  end

  -- Additional checks for Neo-tree specific cases
  local buf_name = vim.api.nvim_buf_get_name(buf_id)
  if buf_name:match('neo%-tree') or buf_name:match('NvimTree') then
    return false
  end

  -- Check if window is very small (likely a popup or split)
  if config.exclude.small_windows then
    local win_height = vim.api.nvim_win_get_height(win_id)
    local win_width = vim.api.nvim_win_get_width(win_id)
    local min_height = config.exclude.small_windows.min_height or 3
    local min_width = config.exclude.small_windows.min_width or 20

    if win_height < min_height or win_width < min_width then
      return false
    end
  end

  return true
end

-- Function to set statusline for current window
local function set_window_statusline()
  local win_id = vim.api.nvim_get_current_win()
  if should_have_statusline(win_id) then
    vim.wo[win_id].statusline = '%!v:lua.require("custom_ui.statusline").statusline()'
  else
    -- Explicitly disable statusline for windows that shouldn't have it
    vim.wo[win_id].statusline = ''
  end
end

-- Function to handle all windows (useful for refreshing)
local function refresh_all_statuslines()
  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_win_call(win_id, function ()
        if should_have_statusline(win_id) then
          vim.wo[win_id].statusline = '%!v:lua.require("custom_ui.statusline").statusline()'
        else
          vim.wo[win_id].statusline = ''
        end
      end)
    end
  end
end

-- Setup function
function M.setup(user_config)
  config = vim.tbl_deep_extend('force', config, user_config or {})
  setup_highlights()

  -- Set up autocommands for cache invalidation and window-local statuslines
  local group = vim.api.nvim_create_augroup('StatuslineUpdate', { clear = true })

  vim.api.nvim_create_autocmd({ 'ModeChanged' }, {
    group = group,
    callback = function ()
      cache.mode = nil
    end
  })

  vim.api.nvim_create_autocmd({
    'BufEnter', 'BufWritePost', 'TextChanged', 'TextChangedI', 'BufModifiedSet'
  }, {
    group = group,
    callback = function ()
      cache.file_info = nil
    end
  })

  vim.api.nvim_create_autocmd({ 'DiagnosticChanged' }, {
    group = group,
    callback = function ()
      cache.diagnostics = nil
    end
  })

  vim.api.nvim_create_autocmd({ 'LspAttach', 'LspDetach' }, {
    group = group,
    callback = function ()
      cache.lsp_status = nil
    end
  })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = group,
    callback = function ()
      cache.position = nil
      cache.percentage = nil
    end
  })

  -- Window resize events to refresh centering calculations
  vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
    group = group,
    callback = function ()
      -- Force statusline refresh on window size change
      vim.cmd('redrawstatus')
    end
  })

  -- Set up window-local statuslines with better event handling
  vim.api.nvim_create_autocmd({ 'WinEnter', 'BufWinEnter', 'WinNew' }, {
    group = group,
    callback = function ()
      -- Small delay to ensure window is fully initialized
      vim.schedule(set_window_statusline)
    end,
    desc = 'Set window-local statusline'
  })

  -- Handle floating windows specifically
  vim.api.nvim_create_autocmd({ 'WinNew' }, {
    group = group,
    callback = function ()
      vim.schedule(function ()
        local win_id = vim.api.nvim_get_current_win()
        local win_config = vim.api.nvim_win_get_config(win_id)
        -- Force disable statusline for floating windows
        if win_config.relative ~= '' then
          vim.wo[win_id].statusline = ''
        end
      end)
    end,
    desc = 'Disable statusline for floating windows'
  })

  -- Handle window closing to clean up
  vim.api.nvim_create_autocmd({ 'WinClosed' }, {
    group = group,
    callback = function ()
      -- Clear any cached data that might be window-specific
      -- This helps prevent memory leaks in long sessions
      vim.schedule(function ()
        collectgarbage('collect')
      end)
    end
  })

  -- Global refresh on certain events that might affect window layout
  vim.api.nvim_create_autocmd({ 'TabEnter', 'SessionLoadPost' }, {
    group = group,
    callback = function ()
      vim.schedule(refresh_all_statuslines)
    end,
    desc = 'Refresh all statuslines on layout changes'
  })

  -- Set statusline for current window immediately
  set_window_statusline()
end

-- Auto-setup with default config
M.setup()

return M
