-- statusline/events.lua
local M = {}

local cache = require('statusline.cache')
local utils = require('statusline.utils')
local loader = require('statusline.loader')

--[[
  Setup autocommands for statusline updates
--]]
function M.setup()
  local group = vim.api.nvim_create_augroup('CustomStatusline', { clear = true })
  local autocmd = vim.api.nvim_create_autocmd

  -- Mode changes
  autocmd('ModeChanged', {
    group = group,
    pattern = "*",
    callback = function ()
      cache.invalidate('mode')
      vim.schedule(utils.refresh_current_statusline)
    end
  })

  -- File and buffer changes
  autocmd({
    'BufEnter', 'BufWritePost', 'TextChanged', 'TextChangedI',
    'BufModifiedSet', 'LspAttach', 'LspDetach'
  }, {
    group = group,
    pattern = "*",
    callback = function ()
      cache.invalidate('file_info')
      cache.invalidate('lsp_status')

      vim.schedule(function ()
        loader.check_lazy_components()
        utils.refresh_current_statusline()
      end)
    end
  })

  -- Diagnostic changes
  autocmd('DiagnosticChanged', {
    group = group,
    pattern = "*",
    callback = function ()
      cache.invalidate('diagnostics')
      vim.schedule(utils.refresh_current_statusline)
    end
  })

  -- Cursor movement (throttled)
  autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = group,
    pattern = "*",
    callback = utils.throttled_cursor_update
  })

  -- Git branch updates
  autocmd({ 'FocusGained', 'DirChanged', 'BufEnter' }, {
    group = group,
    pattern = "*",
    callback = function ()
      cache.invalidate('git_branch')
      vim.schedule(utils.refresh_current_statusline)
    end
  })

  -- Window resizing
  autocmd({ 'VimResized', 'WinResized' }, {
    group = group,
    pattern = "*",
    callback = function ()
      vim.schedule(utils.debounced_redraw)
    end
  })

  -- Window focus changes
  autocmd({ 'WinEnter', 'BufWinEnter', 'WinNew' }, {
    group = group,
    pattern = "*",
    callback = function ()
      vim.schedule(utils.refresh_current_statusline)
    end
  })

  -- Tab and session changes
  autocmd({ 'TabEnter', 'SessionLoadPost' }, {
    group = group,
    pattern = "*",
    callback = function ()
      vim.schedule(utils.refresh_all_statuslines)
    end
  })

  -- Colorscheme changes
  autocmd('ColorScheme', {
    group = group,
    pattern = "*",
    callback = function ()
      local highlights = require('statusline.highlights')
      highlights.apply_colorscheme_highlights()
      vim.schedule(utils.refresh_all_statuslines)
    end
  })

  -- LSP progress updates (if available)
  if vim.lsp.handlers then
    autocmd('LspProgress', {
      group = group,
      pattern = "*",
      callback = function ()
        cache.invalidate('lsp_status')
        vim.schedule(utils.refresh_current_statusline)
      end
    })
  end
end

--[[
  Clean up autocommands
--]]
function M.cleanup()
  vim.api.nvim_del_augroup_by_name('CustomStatusline')
end

--[[
  Manually trigger statusline refresh
--]]
function M.refresh()
  vim.schedule(utils.refresh_all_statuslines)
end

--[[
  Force refresh with cache invalidation
--]]
function M.force_refresh()
  cache.clear()
  loader.reset()
  vim.schedule(utils.refresh_all_statuslines)
end

--[[
  Setup file watching for git changes (experimental)
--]]
function M.setup_git_watcher()
  local function watch_git_head()
    local git_dir = vim.fn.finddir('.git', vim.fn.expand('%:p:h') .. ';')
    if git_dir == '' then return end

    local head_file = git_dir .. '/HEAD'
    if vim.fn.filereadable(head_file) == 0 then return end

    -- Watch for changes to git HEAD
    vim.schedule(function ()
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'FocusGained' }, {
        group = vim.api.nvim_create_augroup('GitWatch', { clear = true }),
        callback = function ()
          cache.invalidate('git_branch')
          utils.refresh_current_statusline()
        end
      })
    end)
  end

  -- Only setup if in a git repository
  if vim.fn.isdirectory('.git') == 1 then
    watch_git_head()
  end
end

--[[
  Get event statistics for debugging
--]]
function M.get_event_stats()
  local augroup_id = vim.api.nvim_create_augroup('CustomStatusline', { clear = false })
  local autocmds = vim.api.nvim_get_autocmds({ group = augroup_id })

  return {
    augroup_id = augroup_id,
    autocmd_count = #autocmds,
    events = vim.tbl_map(function (autocmd)
      return autocmd.event
    end, autocmds)
  }
end

return M
