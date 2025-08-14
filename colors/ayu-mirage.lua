local g = vim.g
local o = vim.o
local cmd = vim.cmd
local api = vim.api

-- Clear existing highlights and reset syntax
cmd.highlight("clear")
if vim.fn.exists("syntax_on") then
  cmd.syntax("reset")
end

o.termguicolors = true
g.colors_name = "ayu-mirage"

-- Import palette and highlights
local p = require("themes.ayu-mirage.palette")
local h = require("themes.ayu-mirage.highlights")

-- Set highlights
local hl = api.nvim_set_hl
for group, opts in pairs(h.get_highlights(p)) do
  hl(0, group, opts)
end

-- LSP semantic token priority handling
local key_priorities = {
  ["constant"] = 127,
  ["constant.builtin"] = 127,
  ["variable.builtin"] = 127
}

api.nvim_create_autocmd("LspTokenUpdate", {
  callback = function(args)
    local t = args.data.token
    local cap = vim.treesitter.get_captures_at_pos(args.buf, t.line, t.start_col)

    for _, x in ipairs(cap) do
      local priority = key_priorities[x.capture]
      if priority then
        vim.lsp.semantic_tokens.highlight_token(t, args.buf, args.data.client_id, "@" .. x.capture,
          { priority = priority })
        return
      end
    end
  end,
})
