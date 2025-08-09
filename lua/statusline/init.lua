-- statusline/init.lua
local M = {}

local config = require('statusline.config')
local cache = require('statusline.cache')
local components = require('statusline.components')
local utils = require('statusline.utils')
local highlights = require('statusline.highlights')
local events = require('statusline.events')

--[[
  Main Statusline Builder
--]]
function M.statusline()
  local win_id = vim.api.nvim_get_current_win()
  local left_parts = {}
  local right_parts = {}
  local right_components = {} -- Track component names for width calculation

  -- Left section
  table.insert(left_parts, components.mode())

  local git = components.git_branch()
  if git ~= '' then
    table.insert(left_parts, git)
  end

  -- Right section
  local diagnostics = components.diagnostics()
  if diagnostics ~= '' then
    table.insert(right_parts, diagnostics)
    table.insert(right_components, 'diagnostics')
  end

  local lsp = components.lsp_status()
  if lsp ~= '' then
    table.insert(right_parts, lsp)
    table.insert(right_components, 'lsp_status')
  end

  if config.get().components.encoding then
    local enc = components.encoding()
    table.insert(right_parts, enc)
    table.insert(right_components, 'encoding')
  end

  local pos = components.position()
  table.insert(right_parts, pos)
  table.insert(right_components, 'position')

  if config.get().components.percentage then
    local perc = components.percentage()
    table.insert(right_parts, perc)
    table.insert(right_components, 'percentage')
  end

  -- Build final statusline
  local left_section = table.concat(left_parts, ' ')
  local right_section = table.concat(right_parts, config.get().separators.section)
  local center_section = components.file_info()

  return utils.build_statusline(left_section, center_section, right_section, right_components, win_id)
end

--[[
  Setup function
--]]
function M.setup(user_config)
  config.setup(user_config)
  highlights.setup()
  events.setup()

  -- Initialize all statuslines
  utils.refresh_all_statuslines(M.statusline)
end

-- Export profile function for debugging
function M.get_profile()
  return components.get_profile()
end

return M
