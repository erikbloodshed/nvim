local g = vim.g
local o = vim.o
local wo = vim.wo
local opt = vim.opt

g.loaded_node_provider = 0
g.loaded_perl_provider = 0
g.loaded_python3_provider = 0
g.loaded_ruby_provider = 0

if vim.fn.has("wsl") == 1 then
  g.clipboard = {
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
  o.clipboard = "unnamedplus"
end

o.updatetime = 250
o.timeoutlen = 300
o.ttimeoutlen = 10
o.hidden = true
o.history = 100

o.number = true
o.showtabline = 0
o.splitright = true
o.swapfile = false
o.synmaxcol = 128
wo.signcolumn = "yes:1"
-- setw.cursorline = true

o.autowrite = false
o.expandtab = true
o.shiftwidth = 4
o.smartindent = false
o.smarttab = false
o.softtabstop = 4
o.tabstop = 4
o.wrap = false
o.laststatus = 2
o.showmode = false
o.foldmethod = "marker"
o.foldcolumn = "0"

opt.viewoptions:append({ options = true })
opt.shortmess:append("cC")
opt.formatoptions:remove({ "c", "r", "o" })
opt.fillchars:append({ eob = " " })
