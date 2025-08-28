local g, o, api = vim.g, vim.o, vim.api

if g.colors_name then
  vim.cmd.highlight("clear")
end

g.colors_name = "decaf"
o.termguicolors = true

local s = {
  transparency = false,
  float = {
    transparent = false,
    solid = true,
  },
}

local c = require("themes.decaf.colors")

local mod = {
  require("themes.decaf.schema.native_lsp").get(c, s),
  require("themes.decaf.schema.editor").get(c, s),
  require("themes.decaf.schema.neotree").get(c, s),
  require("themes.decaf.schema.blink").get(c),
  require("themes.decaf.schema.syntax").get(c),
  require("themes.decaf.schema.treesitter").get(c),
  require("themes.decaf.schema.semantic_tokens").get(),
}

local hls = {}
for _, m in pairs(mod) do
  for n, a in pairs(m) do hls[n] = a end
end

local hl = api.nvim_set_hl
for n, a in pairs(hls) do hl(0, n, a) end

local t = require("themes.decaf.schema.terminal").get(c)
for i, k in pairs(t) do
  vim.g[i] = k
end
