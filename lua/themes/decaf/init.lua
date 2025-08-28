return {
  load = function()
    local g, o, api = vim.g, vim.o, vim.api

    if g.colors_name then
      vim.cmd.highlight("clear")
    end

    g.colors_name   = "decaf"
    o.termguicolors = true

    local s         = {
      transparency = false,
      float = {
        transparent = false,
        solid = true,
      },
    }

    local c         = require("themes.decaf.colors")
    local hls       = require("themes.decaf.schema.schema").get(c, s)
    local hl        = api.nvim_set_hl
    for n, a in pairs(hls) do hl(0, n, a) end

    local t = require("themes.decaf.schema.terminal").get(c)
    for i, k in pairs(t) do
      vim.g[i] = k
    end
  end
}
