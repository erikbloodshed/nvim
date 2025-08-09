local M = {}

--[[
  Default Configuration
  This table can be overridden by the user during the setup() call.
--]]
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
    modified = '',
    readonly = '',
    git = '',
    error = '',
    warn = '',
    info = '',
    hint = '',
    lsp = '',
  },

  center_filename = true, -- Controls whether the filename is centered.
  exclude = {
    buftypes = { 'terminal', 'quickfix', 'help', 'nofile', 'prompt' },
    filetypes = {
      'NvimTree', 'neo-tree', 'aerial', 'Outline', 'packer', 'alpha', 'starter',
      'TelescopePrompt', 'TelescopeResults', 'TelescopePreview',
      'lazy', 'mason', 'lspinfo', 'null-ls-info',
      'checkhealth', 'help', 'man', 'qf', 'fugitive'
    },
    floating_windows = true,                            -- Disable statusline for floating windows.
    small_windows = { min_height = 3, min_width = 20 }, -- Disable for very small windows.
  }
}

--[[
  Mode definitions with corresponding highlight groups.
--]]
local modes = {
  n = { name = 'NORMAL', hl = 'StatusLineNormal' },
  i = { name = 'INSERT', hl = 'StatusLineInsert' },
  v = { name = 'VISUAL', hl = 'StatusLineVisual' },
  V = { name = 'V-LINE', hl = 'StatusLineVisual' },
  ['\22'] = { name = 'V-BLOCK', hl = 'StatusLineVisual' },
  c = { name = 'COMMAND', hl = 'StatusLineCommand' },
  R = { name = 'REPLACE', hl = 'StatusLineReplace' },
  r = { name = 'REPLACE', hl = 'StatusLineReplace' },
  s = { name = 'SELECT', hl = 'StatusLineVisual' },
  S = { name = 'S-LINE', hl = 'StatusLineVisual' },
  ['\19'] = { name = 'S-BLOCK', hl = 'StatusLineVisual' },
  t = { name = 'TERMINAL', hl = 'StatusLineTerminal' },
}

--[[
  Sets up the default highlight groups for the statusline.
--]]
local function setup_highlights()
  local highlights = {
    StatusLineNormal = { fg = '#bd93f9', bg = 'NONE', bold = true },
    StatusLineInsert = { fg = '#50fa7b', bg = 'NONE', bold = true },
    StatusLineVisual = { fg = '#ff79c6', bg = 'NONE', bold = true },
    StatusLineCommand = { fg = '#f1fa8c', bg = 'NONE', bold = true },
    StatusLineReplace = { fg = '#ffb86c', bg = 'NONE', bold = true },
    StatusLineTerminal = { fg = '#8be9fd', bg = 'NONE', bold = true },
    StatusLineFile = { fg = '#f8f8f2', bg = 'NONE' },
    StatusLineModified = { fg = '#f1fa8c', bg = 'NONE', bold = true },
    StatusLineReadonly = { fg = '#6272a4', bg = 'NONE' },
    StatusLineGit = { fg = '#ffb86c', bg = 'NONE' },
    StatusLineInfo = { fg = '#6272a4', bg = 'NONE' },
    StatusLineDiagError = { fg = '#ff5555', bg = 'NONE' },
    StatusLineDiagWarn = { fg = '#f1fa8c', bg = 'NONE' },
    StatusLineDiagInfo = { fg = '#8be9fd', bg = 'NONE' },
    StatusLineDiagHint = { fg = '#50fa7b', bg = 'NONE' },
    StatusLineLSP = { fg = '#50fa7b', bg = 'NONE' },
  }
  for name, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

--[[
  Smart Cache with TTL (Time-To-Live).
--]]
local cache = {
  data = {},
  last_update = {},
  update_intervals = {
    mode = 50,
    file_info = 200,
    position = 100,
    percentage = 100,
    git_branch = 10000,
    diagnostics = 1000,
    lsp_status = 2000,
    encoding = 30000,
  }
}

local function is_cache_valid(component, force_refresh)
  if force_refresh then return false end
  local ttl = cache.update_intervals[component] or 1000
  local now = vim.loop.hrtime() / 1e6
  local last_update = cache.last_update[component] or 0
  return (now - last_update) < ttl and cache.data[component] ~= nil
end

local function update_cache(component, value)
  cache.data[component] = value
  cache.last_update[component] = vim.loop.hrtime() / 1e6
end

local function invalidate_cache(component)
  cache.data[component] = nil
  cache.last_update[component] = nil
end

--[[
  Lazy Component Loader
  Checks if dependencies are available before loading a component.
--]]
local ComponentLoader = {}
ComponentLoader.__index = ComponentLoader

function ComponentLoader:new()
  return setmetatable({
    loaded_components = {},
    lazy_components = {},
    dependencies = {
      file_info = { 'nvim-web-devicons' },
      diagnostics = { 'vim.diagnostic' },
      lsp_status = { 'vim.lsp' }
    }
  }, self)
end

function ComponentLoader:is_dependency_available(dep)
  if dep == 'vim.diagnostic' then return vim.diagnostic ~= nil end
  if dep == 'vim.lsp' then return vim.lsp ~= nil end
  return pcall(require, dep)
end

function ComponentLoader:check_dependencies(component)
  local deps = self.dependencies[component] or {}
  if #deps == 0 then return true end -- No dependencies to check
  for _, dep in ipairs(deps) do
    if self:is_dependency_available(dep) then
      return true -- At least one dependency is available
    end
  end
  return false
end

function ComponentLoader:should_load_component(component)
  if self.loaded_components[component] then return true end
  if not config.components[component] then return false end

  if not self:check_dependencies(component) then
    self.lazy_components[component] = true
    return false
  end

  self.loaded_components[component] = true
  self.lazy_components[component] = nil
  return true
end

function ComponentLoader:check_lazy_components()
  for component, _ in pairs(self.lazy_components) do
    if self:check_dependencies(component) then
      self:should_load_component(component) -- This will move it to loaded
    end
  end
end

local loader = ComponentLoader:new()

--[[
  Component Builder Functions
--]]
local components = {}

function components.mode()
  if not loader:should_load_component('mode') then return '' end
  if is_cache_valid('mode') then return cache.data.mode end

  local current_mode = vim.api.nvim_get_mode().mode
  local mode_info = modes[current_mode] or { name = 'UNKNOWN', hl = 'StatusLineNormal' }
  local result = string.format('%%#%s# %s %%*', mode_info.hl, mode_info.name)

  update_cache('mode', result)
  return result
end

function components.file_info()
  if not loader:should_load_component('file_info') then return '' end
  if is_cache_valid('file_info') then return cache.data.file_info end

  local parts = {}
  local filename = vim.fn.expand('%:t')
  if filename == '' then filename = '[No Name]' end

  local icon = ''
  local devicons_ok, devicons = pcall(require, 'nvim-web-devicons')
  if devicons_ok then
    local extension = vim.fn.expand('%:e')
    icon = devicons.get_icon(filename, extension, { default = true }) .. ' '
  end

  if vim.bo.readonly then
    table.insert(parts, '%#StatusLineReadonly#' .. config.icons.readonly .. '%*')
  end

  if vim.bo.modified then
    table.insert(parts, '%#StatusLineModified#' .. icon .. filename .. ' ' .. config.icons.modified .. '%*')
  else
    table.insert(parts, '%#StatusLineFile#' .. icon .. filename .. '%*')
  end

  local result = table.concat(parts, ' ')
  update_cache('file_info', result)
  return result
end

function components.git_branch()
  if not loader:should_load_component('git_branch') then return '' end
  if is_cache_valid('git_branch') then return cache.data.git_branch end

  -- Non-blocking git command
  local cwd = vim.fn.expand('%:p:h')
  if cwd ~= '' and vim.system then
    vim.system({ 'git', 'branch', '--show-current' }, { cwd = cwd, text = true }, vim.schedule_wrap(function (obj)
      local git_result = ''
      if obj.code == 0 and obj.stdout ~= '' then
        local git_branch = obj.stdout:gsub('[\n\r]', '') -- Clean newline characters
        if git_branch ~= '' then
          git_result = string.format('%%#StatusLineGit#%s %s%%*', config.icons.git, git_branch)
        end
      end
      -- Update cache only if value changes, and redraw
      if cache.data.git_branch ~= git_result then
        update_cache('git_branch', git_result)
        vim.cmd('redrawstatus')
      end
    end))
  end
  -- Return cached value or empty string while job runs
  return cache.data.git_branch or ''
end

function components.diagnostics()
  if not loader:should_load_component('diagnostics') then return '' end
  if is_cache_valid('diagnostics') then return cache.data.diagnostics end

  local counts = { error = 0, warn = 0, info = 0, hint = 0 }
  for _, diag in ipairs(vim.diagnostic.get(0)) do
    if diag.severity == 1 then
      counts.error = counts.error + 1
    elseif diag.severity == 2 then
      counts.warn = counts.warn + 1
    elseif diag.severity == 3 then
      counts.info = counts.info + 1
    elseif diag.severity == 4 then
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
  if not loader:should_load_component('lsp_status') then return '' end
  if is_cache_valid('lsp_status') then return cache.data.lsp_status end

  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    update_cache('lsp_status', '')
    return ''
  end

  local client_names = {}
  for _, client in ipairs(clients) do
    table.insert(client_names, client.name)
  end

  local result = ''
  if #client_names > 0 then
    result = string.format('%%#StatusLineLSP#%s %s%%*', config.icons.lsp, table.concat(client_names, ', '))
  end

  update_cache('lsp_status', result)
  return result
end

function components.encoding()
  if not loader:should_load_component('encoding') then return '' end
  if is_cache_valid('encoding') then return cache.data.encoding end

  local enc = vim.bo.fileencoding
  if enc == '' then enc = vim.o.encoding end
  local result = '%#StatusLineInfo#' .. enc:upper() .. '%*'

  update_cache('encoding', result)
  return result
end

function components.position()
  if not loader:should_load_component('position') then return '' end
  if is_cache_valid('position') then return cache.data.position end

  local result = string.format('%%#StatusLineInfo#Ln %d, Col %d%%*', vim.fn.line('.'), vim.fn.col('.'))
  update_cache('position', result)
  return result
end

function components.percentage()
  if not loader:should_load_component('percentage') then return '' end
  if is_cache_valid('percentage') then return cache.data.percentage end

  local curr_line = vim.fn.line('.')
  local total_lines = vim.fn.line('$')
  local percentage = total_lines > 0 and math.floor((curr_line / total_lines) * 100) or 0
  local result = string.format('%%#StatusLineInfo#%d%%%%%%*', percentage)

  update_cache('percentage', result)
  return result
end

--[[
  Utility function to get the display width of a statusline string.
--]]
local function get_display_width(str)
  local clean_str = str:gsub('%%#[^#]*#', ''):gsub('%%*', '')
  clean_str = clean_str:gsub('%%=', ''):gsub('%%<', '')
  return vim.fn.strdisplaywidth(clean_str)
end

--[[
  Main Statusline Builder
--]]
function M.statusline()
  local win_id = vim.api.nvim_get_current_win()

  local left_parts = {}
  local right_parts = {}

  table.insert(left_parts, components.mode())
  local git = components.git_branch()
  if git ~= '' then table.insert(left_parts, git) end

  local diagnostics = components.diagnostics()
  if diagnostics ~= '' then table.insert(right_parts, diagnostics) end

  local lsp = components.lsp_status()
  if lsp ~= '' then table.insert(right_parts, lsp) end

  if config.components.encoding then table.insert(right_parts, components.encoding()) end
  table.insert(right_parts, components.position())
  if config.components.percentage then table.insert(right_parts, components.percentage()) end

  local left_section = table.concat(left_parts, ' ')
  local right_section = table.concat(right_parts, config.separators.section)
  local center_section = components.file_info()

  if config.center_filename then
    local left_width = get_display_width(left_section)
    local right_width = get_display_width(right_section)
    local center_width = get_display_width(center_section)
    local win_width = vim.api.nvim_win_get_width(win_id)

    local total_side_width = left_width + right_width
    local available_center = win_width - total_side_width

    if available_center < center_width + 4 then
      -- Fallback to simple layout if there is not enough space
      return left_section .. ' ' .. center_section .. '%=' .. right_section
    end

    local center_start = math.floor((win_width - center_width) / 2)
    local left_padding = math.max(1, center_start - left_width)

    local statusline = left_section
    statusline = statusline .. string.rep(' ', left_padding)
    statusline = statusline .. center_section
    statusline = statusline .. '%=' -- Align right section to the right
    statusline = statusline .. right_section

    return statusline
  else
    return left_section .. ' ' .. center_section .. '%=' .. right_section
  end
end

--[[
  Conditional Logic for Displaying the Statusline
--]]
local function should_have_statusline(win_id)
  if config.exclude.floating_windows and vim.api.nvim_win_get_config(win_id).relative ~= '' then
    return false
  end

  local buf_id = vim.api.nvim_win_get_buf(win_id)
  local buf_type = vim.api.nvim_get_option_value('buftype', { buf = buf_id })
  local file_type = vim.api.nvim_get_option_value('filetype', { buf = buf_id })

  for _, skip_type in ipairs(config.exclude.buftypes) do
    if buf_type == skip_type then return false end
  end

  for _, skip_type in ipairs(config.exclude.filetypes) do
    if file_type == skip_type then return false end
  end

  if config.exclude.small_windows then
    local win_height = vim.api.nvim_win_get_height(win_id)
    local win_width = vim.api.nvim_win_get_width(win_id)
    if win_height < (config.exclude.small_windows.min_height or 3) or win_width < (config.exclude.small_windows.min_width or 20) then
      return false
    end
  end

  return true
end

--[[
  Setup and Autocommands
--]]
local function set_window_statusline()
  local win_id = vim.api.nvim_get_current_win()
  if should_have_statusline(win_id) then
    vim.wo[win_id].statusline = '%!v:lua.require("custom_ui.statusline").statusline()'
  else
    vim.wo[win_id].statusline = ''
  end
end

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

function M.setup(user_config)
  config = vim.tbl_deep_extend('force', config, user_config or {})
  setup_highlights()

  local group = vim.api.nvim_create_augroup('CustomStatusline', { clear = true })
  local autocmd = vim.api.nvim_create_autocmd

  autocmd('ModeChanged', { group = group, pattern = "*", callback = function () invalidate_cache('mode') end })

  autocmd({ 'BufEnter', 'BufWritePost', 'TextChanged', 'TextChangedI', 'BufModifiedSet' }, {
    group = group,
    pattern = "*",
    callback = function ()
      invalidate_cache('file_info')
      vim.schedule(function () loader:check_lazy_components() end)
    end
  })

  autocmd('DiagnosticChanged',
    { group = group, pattern = "*", callback = function () invalidate_cache('diagnostics') end })

  autocmd({ 'LspAttach', 'LspDetach' }, {
    group = group,
    pattern = "*",
    callback = function ()
      invalidate_cache('lsp_status')
      vim.schedule(function () loader:check_lazy_components() end)
    end
  })

  autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = group,
    pattern = "*",
    callback = function ()
      invalidate_cache('position')
      invalidate_cache('percentage')
    end
  })

  autocmd({ 'FocusGained', 'DirChanged', 'BufEnter' },
    { group = group, pattern = "*", callback = function () invalidate_cache('git_branch') end })

  autocmd({ 'VimResized', 'WinResized' }, { group = group, pattern = "*", command = 'redrawstatus' })

  autocmd({ 'WinEnter', 'BufWinEnter', 'WinNew' }, {
    group = group,
    pattern = "*",
    callback = function () vim.schedule(set_window_statusline) end
  })
  autocmd({ 'TabEnter', 'SessionLoadPost' }, {
    group = group,
    pattern = "*",
    callback = function () vim.schedule(refresh_all_statuslines) end
  })

  -- Initial setup
  refresh_all_statuslines()
end

return M
