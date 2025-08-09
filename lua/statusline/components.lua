-- statusline/components.lua
local M = {}

local config = require('statusline.config')
local cache = require('statusline.cache')
local loader = require('statusline.loader')
local profiler = require('statusline.profiler')

--[[
  Mode definitions with corresponding highlight groups
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

-- Git job tracker
local git_job = nil

--[[
  Mode Component
--]]
M.mode = profiler.wrap('mode', function ()
  if not loader:should_load_component('mode') then return '' end
  if cache.is_valid('mode') then return cache.get('mode') end

  local current_mode = vim.api.nvim_get_mode().mode
  local mode_info = modes[current_mode] or { name = 'UNKNOWN', hl = 'StatusLineNormal' }
  local result = string.format('%%#%s# %s %%*', mode_info.hl, mode_info.name)

  cache.update('mode', result)
  return result
end)

--[[
  File Info Component
--]]
M.file_info = profiler.wrap('file_info', function ()
  if not loader:should_load_component('file_info') then return '' end
  if cache.is_valid('file_info') then return cache.get('file_info') end

  local filename = vim.fn.expand('%:t')
  if filename == '' then filename = '[No Name]' end

  -- Get file icon
  local icon = cache.get('file_icon') or ''
  if icon == '' then
    local devicons_ok, devicons = pcall(require, 'nvim-web-devicons')
    if devicons_ok then
      local extension = vim.fn.expand('%:e')
      icon = devicons.get_icon(filename, extension, { default = true }) .. ' '
      cache.update('file_icon', icon)
    end
  end

  local parts = {}
  local icons = config.get().icons

  -- Readonly indicator
  if vim.bo.readonly then
    table.insert(parts, string.format('%%#StatusLineReadonly#%s%%*', icons.readonly))
  end

  -- Filename with modification indicator
  table.insert(parts, string.format('%%#StatusLine%s#%s%s%s%%*',
    vim.bo.modified and 'Modified' or 'File',
    icon,
    filename,
    vim.bo.modified and ' ' .. icons.modified or ''
  ))

  local result = table.concat(parts, ' ')
  cache.update('file_info', result)
  return result
end)

--[[
  Git Branch Component
--]]
M.git_branch = profiler.wrap('git_branch', function ()
  if not loader:should_load_component('git_branch') then return '' end
  if cache.is_valid('git_branch') then return cache.get('git_branch') end

  local cwd = vim.fn.expand('%:p:h')
  if cwd ~= '' and vim.system then
    -- Kill existing job if running
    if git_job and git_job.is_running and git_job:is_running() then
      git_job:kill()
    end

    git_job = vim.system({ 'git', 'branch', '--show-current' },
      { cwd = cwd, text = true },
      vim.schedule_wrap(function (obj)
        git_job = nil
        local git_result = ''

        if obj.code == 0 and obj.stdout ~= '' then
          local git_branch = obj.stdout:gsub('[\n\r]', '')
          if git_branch ~= '' then
            local icons = config.get().icons
            git_result = string.format('%%#StatusLineGit#%s %s%%*', icons.git, git_branch)
          end
        end

        if cache.get('git_branch') ~= git_result then
          cache.update('git_branch', git_result)
          local utils = require('statusline.utils')
          vim.schedule(utils.debounced_redraw)
        end
      end)
    )
  end

  return cache.get('git_branch') or ''
end)

--[[
  Diagnostics Component
--]]
M.diagnostics = profiler.wrap('diagnostics', function ()
  if not loader:should_load_component('diagnostics') then return '' end
  if cache.is_valid('diagnostics') then return cache.get('diagnostics') end

  local counts = { error = 0, warn = 0, info = 0, hint = 0 }
  local severity = vim.diagnostic.severity or { ERROR = 1, WARN = 2, INFO = 3, HINT = 4 }

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
  local icons = config.get().icons

  if counts.error > 0 then
    table.insert(parts, string.format('%%#StatusLineDiagError#%s %d%%*', icons.error, counts.error))
  end
  if counts.warn > 0 then
    table.insert(parts, string.format('%%#StatusLineDiagWarn#%s %d%%*', icons.warn, counts.warn))
  end
  if counts.info > 0 then
    table.insert(parts, string.format('%%#StatusLineDiagInfo#%s %d%%*', icons.info, counts.info))
  end
  if counts.hint > 0 then
    table.insert(parts, string.format('%%#StatusLineDiagHint#%s %d%%*', icons.hint, counts.hint))
  end

  local result = table.concat(parts, ' ')
  cache.update('diagnostics', result)
  return result
end)

--[[
  LSP Status Component
--]]
M.lsp_status = profiler.wrap('lsp_status', function ()
  if not loader:should_load_component('lsp_status') then return '' end
  if cache.is_valid('lsp_status') then return cache.get('lsp_status') end

  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    cache.update('lsp_status', '')
    return ''
  end

  local client_names = {}
  for _, client in ipairs(clients) do
    table.insert(client_names, client.name)
  end

  local icons = config.get().icons
  local result = string.format('%%#StatusLineLSP#%s %s%%*',
    icons.lsp, table.concat(client_names, ', '))

  cache.update('lsp_status', result)
  return result
end)

--[[
  Encoding Component
--]]
M.encoding = profiler.wrap('encoding', function ()
  if not loader:should_load_component('encoding') then return '' end
  if cache.is_valid('encoding') then return cache.get('encoding') end

  local enc = vim.bo.fileencoding
  if enc == '' then enc = vim.o.encoding end

  local result = string.format('%%#StatusLineInfo#%s%%*', enc:upper())
  cache.update('encoding', result)
  return result
end)

--[[
  Position Component
--]]
M.position = profiler.wrap('position', function ()
  if not loader:should_load_component('position') then return '' end
  if cache.is_valid('position') then return cache.get('position') end

  local result = string.format('%%#StatusLineInfo#Ln %d, Col %d%%*',
    vim.fn.line('.'), vim.fn.col('.'))

  cache.update('position', result)
  return result
end)

--[[
  Percentage Component
--]]
M.percentage = profiler.wrap('percentage', function ()
  if not loader:should_load_component('percentage') then return '' end
  if cache.is_valid('percentage') then return cache.get('percentage') end

  local curr_line = vim.fn.line('.')
  local total_lines = vim.fn.line('$')
  local percentage = total_lines > 0 and math.floor((curr_line / total_lines) * 100) or 0

  local result = string.format('%%#StatusLineInfo#%d%%%s%%*', percentage, '')
  cache.update('percentage', result)
  return result
end)

-- Export profiling function
function M.get_profile()
  return profiler.get_profile()
end

return M
