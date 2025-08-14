local global = vim.g
local set = vim.o
local setw = vim.wo
local opt = vim.opt

global.loaded_node_provider = 0
global.loaded_perl_provider = 0
global.loaded_python3_provider = 0
global.loaded_ruby_provider = 0

if vim.fn.has("wsl") == 1 then
  global.clipboard = {
    name = "WslClipboard",
    copy = {
      ["+"] = "clip.exe",
      ["*"] = "clip.exe",
    },
    paste = {
      ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = false,
  }
else
  set.clipboard = "unnamedplus"
end

set.updatetime = 250
set.timeoutlen = 300
set.ttimeoutlen = 10
set.hidden = true
set.history = 100

set.number = true
set.showtabline = 0
set.splitright = true
set.swapfile = false
set.synmaxcol = 128
setw.signcolumn = "yes:1"
setw.cursorline = true

set.autowrite = false
set.expandtab = true
set.shiftwidth = 4
set.smartindent = false
set.smarttab = false
set.softtabstop = 4
set.tabstop = 4
set.wrap = false
set.laststatus = 3
set.showmode = false

opt.viewoptions:append({ options = true })
opt.shortmess:append("cC")
opt.formatoptions:remove({ "c", "r", "o" })
opt.fillchars:remove("eob:~")

vim.cmd.colorscheme("ayu-theme")
