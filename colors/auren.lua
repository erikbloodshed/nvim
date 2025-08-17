local g = vim.g
local o = vim.o
local cmd = vim.cmd
local api = vim.api

cmd.highlight("clear")
cmd.syntax("reset")

o.termguicolors = true
g.colors_name = "auren"
g.matchparen_disable_cursor_hl = 1

local p = require("themes.auren.palette")
local base = require("themes.auren.spec.base")
local syntax = require("themes.auren.spec.syntax")
local treesitter = require("themes.auren.spec.treesitter")
local lsp = require("themes.auren.spec.lsp")
local plugins = require("themes.auren.spec.plugins")


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

local h = merge_tables(base, syntax, treesitter, lsp, plugins)
local hl = api.nvim_set_hl
for group, opts in pairs(h) do
  hl(0, group, opts)
end

g.terminal_color_0 = p.terminal.black
g.terminal_color_1 = p.terminal.red
g.terminal_color_2 = p.terminal.green
g.terminal_color_3 = p.terminal.yellow
g.terminal_color_4 = p.terminal.blue
g.terminal_color_5 = p.terminal.magenta
g.terminal_color_6 = p.terminal.cyan
g.terminal_color_7 = p.terminal.white
g.terminal_color_8 = p.terminal.bright_black
g.terminal_color_9 = p.terminal.bright_red
g.terminal_color_10 = p.terminal.bright_green
g.terminal_color_11 = p.terminal.bright_yellow
g.terminal_color_12 = p.terminal.bright_blue
g.terminal_color_13 = p.terminal.bright_magenta
g.terminal_color_14 = p.terminal.bright_cyan
g.terminal_color_15 = p.terminal.bright_white

-- LSP semantic token priority handling
local key_priorities = {
  ["constant"] = 127,
  ["type.builtin"] = 127,
  ["constant.builtin"] = 127,
  ["variable.builtin"] = 127
}

api.nvim_create_autocmd("LspTokenUpdate", {
  callback = function(args)
    local t = args.data.token
    local c = vim.treesitter.get_captures_at_pos(args.buf, t.line, t.start_col)

    for _, x in ipairs(c) do
      local priority = key_priorities[x.capture]
      if priority then
        vim.lsp.semantic_tokens.highlight_token(t, args.buf, args.data.client_id, "@" .. x.capture,
          { priority = priority })
        return
      end
    end
  end,
})
