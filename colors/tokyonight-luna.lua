vim.cmd.highlight("clear")
vim.cmd.syntax("reset")

---@format disable-next
vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "tokyonight-luna"
vim.g.matchparen_disable_cursor_hl = 1

require("themes.tokyonight-luna")(false)
