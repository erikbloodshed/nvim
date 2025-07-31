if vim.g.loaded_termswitch then
    return
end

require("termswitch").setup()
vim.g.loaded_termswitch = 1
