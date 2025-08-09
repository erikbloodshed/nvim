local M = {}

-- Default Configuration
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
  separators = { left = '', right = '', section = ' | ' },
  icons = {
    modified = '[+]',
    readonly = '',
    git = '',
    error = '',
    warn = '',
    info = '',
    hint = '',
    lsp = '',
  },
  center_filename = true,
  enable_profiling = false,
  exclude = {
    buftypes = { 'terminal', 'quickfix', 'help', 'nofile', 'prompt' },
    filetypes = {
      'NvimTree', 'neo-tree', 'aerial', 'Outline', 'packer', 'alpha', 'starter',
      'TelescopePrompt', 'TelescopeResults', 'TelescopePreview',
      'lazy', 'mason', 'lspinfo', 'null-ls-info', 'checkhealth', 'help', 'man', 'qf', 'fugitive'
    },
    floating_windows = true,
    small_windows = { min_height = 3, min_width = 20 },
  }
}

-- Mode definitions
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

-- Setup highlights
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

-- Cache system
local cache = {
  data = {},
  timestamps = {},
  widths = {},
  ttl = {
    mode = 50,
    file_info = 200,
    position = 100,
    percentage = 100,
    git_branch = 60000,
    diagnostics = 1000,
    lsp_status = 2000,
    encoding = 120000,
  }
}

-- Profiling system
local profile = { times = {}, counts = {} }

local function with_profile(name, fn)
  if not config.enable_profiling then return fn end
  return function (...)
    local start = vim.loop.hrtime()
    local result = fn(...)
    local elapsed = (vim.loop.hrtime() - start) / 1e6
    profile.times[name] = (profile.times[name] or 0) + elapsed
    profile.counts[name] = (profile.counts[name] or 0) + 1
    return result
  end
end

function M.get_profile()
  return vim.deepcopy(profile)
end

-- Cache utilities
local function is_cache_valid(key, force_refresh)
  if force_refresh then return false end
  if not cache.data[key] or not cache.timestamps[key] then return false end
  local now = vim.loop.hrtime() / 1e6
  local ttl = cache.ttl[key] or 1000
  return (now - cache.timestamps[key]) < ttl
end

local function update_cache(key, value)
  cache.data[key] = value
  cache.timestamps[key] = vim.loop.hrtime() / 1e6
  cache.widths[key] = M.get_display_width(value)
end

local function invalidate_cache(keys)
  if type(keys) == 'string' then keys = { keys } end
  for _, key in ipairs(keys) do
    cache.data[key] = nil
    cache.timestamps[key] = nil
    cache.widths[key] = nil
  end
end

-- Dependency checking
local dependencies = {
  file_info = function () return pcall(require, 'nvim-web-devicons') end,
  diagnostics = function () return vim.diagnostic ~= nil end,
  lsp_status = function () return vim.lsp ~= nil end
}

local function check_component_available(component)
  if not config.components[component] then return false end
  local dep_check = dependencies[component]
  return not dep_check or dep_check()
end

-- Git job management
local git_job = nil

-- Component functions
local components = {}

components.mode = with_profile('mode', function ()
  if not check_component_available('mode') then return '' end
  if is_cache_valid('mode') then return cache.data.mode end

  local mode = vim.api.nvim_get_mode().mode
  local mode_info = modes[mode] or { name = 'UNKNOWN', hl = 'StatusLineNormal' }
  local result = string.format('%%#%s# %s %%*', mode_info.hl, mode_info.name)
  update_cache('mode', result)
  return result
end)

components.file_info = with_profile('file_info', function ()
  if not check_component_available('file_info') then return '' end
  if is_cache_valid('file_info') then return cache.data.file_info end

  local filename = vim.fn.expand('%:t')
  if filename == '' then filename = '[No Name]' end

  -- Get file icon
  local icon = ''
  if cache.data.file_icon then
    icon = cache.data.file_icon
  else
    local ok, devicons = pcall(require, 'nvim-web-devicons')
    if ok then
      local ext = vim.fn.expand('%:e')
      icon = devicons.get_icon(filename, ext, { default = true })
      if icon then
        icon = icon .. ' '
        cache.data.file_icon = icon
      else
        icon = ''
      end
    end
  end

  local parts = {}
  if vim.bo.readonly then
    table.insert(parts, string.format('%%#StatusLineReadonly#%s%%*', config.icons.readonly))
  end

  table.insert(parts, string.format('%%#StatusLine%s#%s%s%s%%*',
    vim.bo.modified and 'Modified' or 'File',
    icon,
    filename,
    vim.bo.modified and ' ' .. config.icons.modified or ''
  ))

  local result = table.concat(parts, ' ')
  update_cache('file_info', result)
  return result
end)

components.git_branch = with_profile('git_branch', function ()
  if not check_component_available('git_branch') then return '' end
  if is_cache_valid('git_branch') then return cache.data.git_branch end

  local cwd = vim.fn.expand('%:p:h')
  if cwd ~= '' and vim.system then
    -- Kill existing job if running
    if git_job and git_job.kill then
      git_job:kill()
    end

    git_job = vim.system({ 'git', 'branch', '--show-current' }, { cwd = cwd, text = true },
      vim.schedule_wrap(function (obj)
        git_job = nil
        local result = ''
        if obj.code == 0 and obj.stdout ~= '' then
          local branch = obj.stdout:gsub('[\n\r]', '')
          if branch ~= '' then
            result = string.format('%%#StatusLineGit#%s %s%%*', config.icons.git, branch)
          end
        end
        if cache.data.git_branch ~= result then
          update_cache('git_branch', result)
          vim.schedule(function () vim.cmd('redrawstatus') end)
        end
      end))
  end

  return cache.data.git_branch or ''
end)

components.diagnostics = with_profile('diagnostics', function ()
  if not check_component_available('diagnostics') then return '' end
  if is_cache_valid('diagnostics') then return cache.data.diagnostics end

  local counts = { error = 0, warn = 0, info = 0, hint = 0 }
  local severity = vim.diagnostic.severity

  for _, diag in ipairs(vim.diagnostic.get(0)) do
    if diag.severity == severity.ERROR then
      counts.error = counts.error + 1
    elseif diag.severity == severity.WARN then
      counts.warn = counts.warn + 1
    elseif diag.severity == severity.INFO then
      counts.info = counts.info + 1
    elseif diag.severity == severity.HINT then
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
end)

components.lsp_status = with_profile('lsp_status', function ()
  if not check_component_available('lsp_status') then return '' end
  if is_cache_valid('lsp_status') then return cache.data.lsp_status end

  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    update_cache('lsp_status', '')
    return ''
  end

  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  local result = string.format('%%#StatusLineLSP#%s %s%%*', config.icons.lsp, table.concat(names, ', '))
  update_cache('lsp_status', result)
  return result
end)

components.encoding = with_profile('encoding', function ()
  if not check_component_available('encoding') then return '' end
  if is_cache_valid('encoding') then return cache.data.encoding end

  local enc = vim.bo.fileencoding
  if enc == '' then enc = vim.o.encoding end
  local result = string.format('%%#StatusLineInfo#%s%%*', enc:upper())
  update_cache('encoding', result)
  return result
end)

components.position = with_profile('position', function ()
  if not check_component_available('position') then return '' end
  if is_cache_valid('position') then return cache.data.position end

  local result = string.format('%%#StatusLineInfo#Ln %d, Col %d%%*', vim.fn.line('.'), vim.fn.col('.'))
  update_cache('position', result)
  return result
end)

components.percentage = with_profile('percentage', function ()
  if not check_component_available('percentage') then return '' end
  if is_cache_valid('percentage') then return cache.data.percentage end

  local curr = vim.fn.line('.')
  local total = vim.fn.line('$')
  local pct = total > 0 and math.floor((curr / total) * 100) or 0
  local result = string.format('%%#StatusLineInfo#%d%%%%%%*', pct)
  update_cache('percentage', result)
  return result
end)

-- Utility function
function M.get_display_width(str)
  local clean_str = str:gsub('%%#[^#]*#', ''):gsub('%%[*=<]', '')
  return vim.fn.strdisplaywidth(clean_str)
end

-- Main statusline function
function M.statusline()
  local win_id = vim.api.nvim_get_current_win()

  -- Build left section
  local left_parts = {}
  table.insert(left_parts, components.mode())

  local git = components.git_branch()
  if git ~= '' then table.insert(left_parts, git) end

  -- Build right section
  local right_parts = {}
  local right_component_names = {}

  local diag = components.diagnostics()
  if diag ~= '' then
    table.insert(right_parts, diag)
    table.insert(right_component_names, 'diagnostics')
  end

  local lsp = components.lsp_status()
  if lsp ~= '' then
    table.insert(right_parts, lsp)
    table.insert(right_component_names, 'lsp_status')
  end

  if config.components.encoding then
    local enc = components.encoding()
    table.insert(right_parts, enc)
    table.insert(right_component_names, 'encoding')
  end

  local pos = components.position()
  table.insert(right_parts, pos)
  table.insert(right_component_names, 'position')

  if config.components.percentage then
    local pct = components.percentage()
    table.insert(right_parts, pct)
    table.insert(right_component_names, 'percentage')
  end

  local left_section = table.concat(left_parts, ' ')
  local right_section = table.concat(right_parts, config.separators.section)
  local center_section = components.file_info()

  -- Handle centered filename
  if config.center_filename then
    local left_width = (cache.widths.mode or M.get_display_width(left_parts[1] or '')) +
      (git ~= '' and (cache.widths.git_branch or M.get_display_width(git)) or 0)

    local right_width = 0
    for i, part in ipairs(right_parts) do
      local comp_name = right_component_names[i]
      right_width = right_width + (cache.widths[comp_name] or M.get_display_width(part))
    end

    -- Add separator widths
    if #right_parts > 1 then
      right_width = right_width + (#right_parts - 1) * M.get_display_width(config.separators.section)
    end

    local center_width = cache.widths.file_info or M.get_display_width(center_section)
    local win_width = vim.api.nvim_win_get_width(win_id)
    local total_side_width = left_width + right_width
    local available_center = win_width - total_side_width

    if available_center >= center_width + 4 then
      local center_start = math.floor((win_width - center_width) / 2)
      local left_padding = math.max(1, center_start - left_width)
      return left_section .. string.rep(' ', left_padding) .. center_section .. '%=' .. right_section
    end
  end

  return left_section .. ' ' .. center_section .. '%=' .. right_section
end

-- Window filtering
local function should_show_statusline(win_id)
  if config.exclude.floating_windows and vim.api.nvim_win_get_config(win_id).relative ~= '' then
    return false
  end

  local buf_id = vim.api.nvim_win_get_buf(win_id)
  local buftype = vim.api.nvim_get_option_value('buftype', { buf = buf_id })
  local filetype = vim.api.nvim_get_option_value('filetype', { buf = buf_id })

  for _, bt in ipairs(config.exclude.buftypes) do
    if buftype == bt then return false end
  end
  for _, ft in ipairs(config.exclude.filetypes) do
    if filetype == ft then return false end
  end

  if config.exclude.small_windows then
    local height = vim.api.nvim_win_get_height(win_id)
    local width = vim.api.nvim_win_get_width(win_id)
    if height < config.exclude.small_windows.min_height or width < config.exclude.small_windows.min_width then
      return false
    end
  end

  return true
end

local statusline_expr = '%!v:lua.require("custom_ui.statusline").statusline()'

local function set_statusline(win_id)
  if vim.api.nvim_win_is_valid(win_id) then
    vim.wo[win_id].statusline = should_show_statusline(win_id) and statusline_expr or ''
  end
end

local function refresh_current_statusline()
  set_statusline(vim.api.nvim_get_current_win())
end

local function refresh_all_statuslines()
  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    set_statusline(win_id)
  end
end


-- Throttled cursor updates
local last_cursor_update = 0
local function throttled_cursor_update()
  local now = vim.loop.hrtime() / 1e6
  if now - last_cursor_update > 50 then
    last_cursor_update = now
    invalidate_cache({ 'position', 'percentage' })
    vim.schedule(refresh_current_statusline)
  end
end

-- Setup function
function M.setup(user_config)
  config = vim.tbl_deep_extend('force', config, user_config or {})
  setup_highlights()

  local group = vim.api.nvim_create_augroup('CustomStatusline', { clear = true })

  vim.api.nvim_create_autocmd('ModeChanged', {
    group = group,
    pattern = "*",
    callback = function ()
      invalidate_cache('mode')
      vim.schedule(refresh_current_statusline)
    end
  })

  vim.api.nvim_create_autocmd(
    { 'BufEnter', 'BufWritePost', 'TextChanged', 'TextChangedI', 'BufModifiedSet', 'LspAttach', 'LspDetach' }, {
      group = group,
      pattern = "*",
      callback = function ()
        invalidate_cache({ 'file_info', 'lsp_status' })
        vim.schedule(refresh_current_statusline)
      end
    })

  vim.api.nvim_create_autocmd('DiagnosticChanged', {
    group = group,
    pattern = "*",
    callback = function ()
      invalidate_cache('diagnostics')
      vim.schedule(refresh_current_statusline)
    end
  })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = group,
    pattern = "*",
    callback = throttled_cursor_update
  })

  vim.api.nvim_create_autocmd({ 'FocusGained', 'DirChanged', 'BufEnter' }, {
    group = group,
    pattern = "*",
    callback = function ()
      invalidate_cache('git_branch')
      vim.schedule(refresh_current_statusline)
    end
  })

  vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
    group = group,
    pattern = "*",
    callback = function ()
      vim.schedule(function () vim.cmd('redrawstatus') end)
    end
  })

  vim.api.nvim_create_autocmd({ 'WinEnter', 'BufWinEnter', 'WinNew' }, {
    group = group,
    pattern = "*",
    callback = function ()
      vim.schedule(refresh_current_statusline)
    end
  })

  vim.api.nvim_create_autocmd({ 'TabEnter', 'SessionLoadPost' }, {
    group = group,
    pattern = "*",
    callback = function ()
      vim.schedule(refresh_all_statuslines)
    end
  })
end

return M
