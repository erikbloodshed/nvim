local g, o, api = vim.g, vim.o, vim.api

if g.colors_name then
  vim.cmd.highlight("clear")
end

g.colors_name = "decaf"
o.termguicolors = true

local cfg = {
  transparency = false,
  float = {
    transparent = false,
    solid = true,
  },
}

local c = require("themes.decaf.colors")

local mod = {
  require("themes.decaf.schema.editor").get(c, cfg),
  require("themes.decaf.schema.native_lsp").get(c, cfg),
  require("themes.decaf.schema.neotree").get(c, cfg),
  require("themes.decaf.schema.syntax").get(c, cfg),
  require("themes.decaf.schema.treesitter").get(c),
  require("themes.decaf.schema.semantic_tokens").get(c),
  require("themes.decaf.schema.blink").get(c),
}

local all_highlights = {}
for _, m in pairs(mod) do
  for n, a in pairs(m) do all_highlights[n] = a end
end

local hl = api.nvim_set_hl
for n, a in pairs(all_highlights) do hl(0, n, a) end


local term = require("themes.decaf.schema.terminal").get(c)
for i, color in pairs(term) do
  vim.g[i] = color
end
