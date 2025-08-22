local g = vim.g
local api = vim.api
local c = require("themes.luna.colors")
local hl = api.nvim_set_hl

vim.cmd.highlight("clear")
vim.cmd.syntax("reset")

vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "tokyonight-luna"
vim.g.matchparen_disable_cursor_hl = 1


-- Optimized approach
local function apply_highlights()
  local modules = {
    require("themes.luna.schema.base"),
    require("themes.luna.schema.treesitter"),
    require("themes.luna.schema.semantic-token"),
    require("themes.luna.schema.status"),
    require("themes.luna.schema.blink"),
    require("themes.luna.schema.neotree"),
  }

  local all_highlights = {}
  for _, mod in ipairs(modules) do
    local highlights = mod.get(c)
    for name, attrs in pairs(highlights) do
      all_highlights[name] = attrs
    end
  end

  for name, attrs in pairs(all_highlights) do
    hl(0, name, attrs)
  end
end

-- Single pcall wrapper
local ok, err = pcall(apply_highlights, c)
if not ok then
  vim.notify("Theme loading failed: " .. err, vim.log.levels.ERROR)
end

g.terminal_color_0 = c.black
g.terminal_color_1 = c.red
g.terminal_color_2 = c.green
g.terminal_color_3 = c.yellow
g.terminal_color_4 = c.blue
g.terminal_color_5 = c.magenta
g.terminal_color_6 = c.cyan
g.terminal_color_7 = c.fg_dark
g.terminal_color_8 = c.br_black
g.terminal_color_9 = c.br_red
g.terminal_color_10 = c.br_green
g.terminal_color_11 = c.br_yellow
g.terminal_color_12 = c.br_blue
g.terminal_color_13 = c.br_magenta
g.terminal_color_14 = c.br_cyan
g.terminal_color_15 = c.br_white

-- local key_priorities = {
--   ["function.builtin"] = 128,
--   -- ["constructor"] = 128,
-- }
--
-- api.nvim_create_autocmd("LspTokenUpdate", {
--   callback = function(args)
--     local t = args.data.token
--     local k = vim.treesitter.get_captures_at_pos(args.buf, t.line, t.start_col)
--
--     for _, x in ipairs(k) do
--       local priority = key_priorities[x.capture]
--       if priority then
--         vim.lsp.semantic_tokens.highlight_token(t, args.buf, args.data.client_id, "@" .. x.capture,
--           { priority = priority })
--         return
--       end
--     end
--   end,
-- })
