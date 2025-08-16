local base = require("themes.ocean-one.highlights.base")
local syntax = require("themes.ocean-one.highlights.syntax")
local treesitter = require("themes.ocean-one.highlights.treesitter")
local lsp = require("themes.ocean-one.highlights.lsp")
local plugins = require("themes.ocean-one.highlights.plugins")

local M = {}

-- Utility function to merge tables
-- local function merge_tables(...)
--   local result = {}
--   for _, tbl in ipairs({...}) do
--     for k, v in pairs(tbl) do
--       result[k] = v
--     end
--   end
--   return result
-- end

local function merge_tables(...)
  local result = {}
  local n = select("#", ...)
  for i = 1, n do
    local tbl = select(i, ...)
    for k, v in next, tbl do
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
