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

  local clients = vim.lsp.get_clients({ bufnr = 0 })
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

-- Main statusline builder
function M.statusline()
  local left_parts = {}
  local center_parts = {}
  local right_parts = {}

  -- Left side
  table.insert(left_parts, components.mode())

  local git = components.git_branch()
  if git ~= '' then
    table.insert(left_parts, git)
  end

  -- Center
  table.insert(center_parts, components.file_info())

  -- Right side
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

  -- Build final statusline
  local left = table.concat(left_parts, ' ')
  local center = table.concat(center_parts, ' ')
  local right = table.concat(right_parts, config.separators.section)

  return left .. '%=' .. center .. '%=' .. right
end

-- Setup function
function M.setup(user_config)
  config = vim.tbl_deep_extend('force', config, user_config or {})
  setup_highlights()

  -- Set up autocommands for cache invalidation
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

  -- Set the statusline
  vim.opt.statusline = '%!v:lua.require("custom_ui.statusline").statusline()'
end

-- Auto-setup with default config
M.setup()

return M
