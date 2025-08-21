local g = vim.g
local api = vim.api
local c = require("themes.luna.colors")
local blend = require("themes.util").blend
local brighten = require("themes.util").brighten
local hl = api.nvim_set_hl

vim.cmd.highlight("clear")
vim.cmd.syntax("reset")

vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "tokyonight-luna"
vim.g.matchparen_disable_cursor_hl = 1


c.dark = blend(c.bg_dark, 0.8, "#000000")             -- #181926
c.bg_visual = blend(c.blue0, 0.35, c.bg)              -- #2b3b6e
c.border_highlight = blend(c.blue1, 0.8, c.bg)        -- #579dd6
c.black = blend(c.bg, 0.8, "#000000")
c.param = brighten(c.red, 0.05)

local s = {
  "themes.luna.schema.base",
  "themes.luna.schema.treesitter",
  "themes.luna.schema.semantic-token",
  "themes.luna.schema.status",
  "themes.luna.schema.blink",
  "themes.luna.schema.neotree",
}

for _, e in ipairs(s) do
  local ok, mod = pcall(require, e)
  if ok then
    local m = mod.get(c)
    for k, v in pairs(m) do hl(0, k, v) end
  else
    vim.notify("Failed to load schema: " .. e, vim.log.levels.WARN)
  end
end

g.terminal_color_0 = c.black
g.terminal_color_1 = c.red
g.terminal_color_2 = c.green
g.terminal_color_3 = c.yellow
g.terminal_color_4 = c.blue
g.terminal_color_5 = c.magenta
g.terminal_color_6 = c.cyan
g.terminal_color_7 = c.fg_dark
g.terminal_color_8 = brighten(c.black)
g.terminal_color_9 = brighten(c.red)
g.terminal_color_10 = brighten(c.green)
g.terminal_color_11 = brighten(c.yellow)
g.terminal_color_12 = brighten(c.blue)
g.terminal_color_13 = brighten(c.magenta)
g.terminal_color_14 = brighten(c.cyan)
g.terminal_color_15 = brighten(c.fg_dark)

local key_priorities = {
  ["function.builtin"] = 128
}

api.nvim_create_autocmd("LspTokenUpdate", {
  callback = function(args)
    local t = args.data.token
    local k = vim.treesitter.get_captures_at_pos(args.buf, t.line, t.start_col)

    for _, x in ipairs(k) do
      local priority = key_priorities[x.capture]
      if priority then
        vim.lsp.semantic_tokens.highlight_token(t, args.buf, args.data.client_id, "@" .. x.capture,
          { priority = priority })
        return
      end
    end
  end,
})
