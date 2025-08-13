local base = require("nord-theme.highlights.base")
local syntax = require("nord-theme.highlights.syntax")
local treesitter = require("nord-theme.highlights.treesitter")
local lsp = require("nord-theme.highlights.lsp")
local plugins = require("nord-theme.highlights.plugins")

local M = {}

-- Utility function to merge tables
local function merge_tables(...)
  local result = {}
  for _, tbl in ipairs({...}) do
    for k, v in pairs(tbl) do
      result[k] = v
    end
  end
  return result
end

-- Function to generate all highlights using the provided palette
function M.get_highlights(palette)
  return merge_tables(
    base.get_highlights(palette),
    syntax.get_highlights(palette),
    treesitter.get_highlights(palette),
    lsp.get_highlights(palette),
    plugins.get_highlights(palette)
  )
end

return M
