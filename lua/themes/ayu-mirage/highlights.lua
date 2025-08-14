local base = require("themes.ayu-mirage.highlights.base")
local syntax = require("themes.ayu-mirage.highlights.syntax")
local treesitter = require("themes.ayu-mirage.highlights.treesitter")
local lsp = require("themes.ayu-mirage.highlights.lsp")
local plugins = require("themes.ayu-mirage.highlights.plugins")

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
function M.get_highlights(p)
  return merge_tables(
    base.get_highlights(p),
    syntax.get_highlights(p),
    treesitter.get_highlights(p),
    lsp.get_highlights(p),
    plugins.get_highlights(p)
  )
end

return M
