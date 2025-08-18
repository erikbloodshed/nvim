--- DISCLAIMER
--- This colorscheme is a derivative work based on tokyonight-moon, a theme
--- created by Folke Lemaitre as part of the tokyonight.nvim suite. While some
--- colors have been modified, the main goal of this refactor is to simplify the
--- colorscheme for personal use while retaining the overall aesthetic and design
--- principles of the original. The core palette and design philosophy originate
--- from Lemaitre’s work.
--- The original tokyonight.nvim project is licensed under the Apache 2.0 License.
--- In accordance with its terms, this derivative work gives full credit to the
--- original author. Please find the original source and its license here:
--- @link: https://github.com/folke/tokyonight.nvim
--- @author: Folke Lemaitre
--- All credit for the foundational design and color theory belongs to him.
local bg_clear = true

vim.cmd.highlight("clear")
vim.cmd.syntax("reset")

---@format disable-next
vim.o.termguicolors = true
vim.g.colors_name = "tokyonight-luna"
vim.g.matchparen_disable_cursor_hl = 1

require("themes.tokyonight-luna").init(bg_clear)
