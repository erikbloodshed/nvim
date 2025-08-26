local g = vim.g
local o = vim.o
local api = vim.api

o.termguicolors = true
o.background = "dark"

if g.colors_name then
  vim.cmd.highlight("clear")
end

g.colors_name = "decaffuccin"

local function apply_highlights()
  local hl = api.nvim_set_hl
  local c = require("themes.decaffuccin.palette.mocka")
  local u = require("themes.decaffuccin.utils")
  local opts = {
    transparent_background = false,
    float = {
      transparent = false,
      solid = false,
    },
    show_end_of_buffer = false,
    term_colors = false,
    dim_inactive = {
      enabled = false,
      shade = "dark",
      percentage = 0.15,
    },
    no_italic = false,
    no_bold = false,
    no_underline = false,
  }

  local modules = {
    require("themes.decaffuccin.schema.editor").get(c, opts, u),
    require("themes.decaffuccin.schema.native_lsp").get(c, opts, u),
    require("themes.decaffuccin.schema.syntax").get(c, opts, u),
    require("themes.decaffuccin.schema.treesitter").get(c),
    require("themes.decaffuccin.schema.semantic_tokens").get(c),
    require("themes.decaffuccin.schema.blink").get(c, u),
    require("themes.decaffuccin.schema.neotree").get(c, opts)
  }

  -- require("themes.decaffuccin.schema.terminal")

  local all_highlights = {}

  for _, mod in pairs(modules) do
    for name, attrs in pairs(mod) do
      all_highlights[name] = attrs
    end
  end

  for name, attrs in pairs(all_highlights) do
    hl(0, name, attrs)
  end
end

local ok, err = pcall(apply_highlights)
if not ok then
  vim.notify("Theme loading failed: " .. err, vim.log.levels.ERROR)
end
