require("sharpsight.remap")
require("sharpsight.packer")
require("sharpsight.init")

vim.o.termguicolors = true
vim.cmd("colorscheme tokyonight")

vim.o.number = true
vim.o.relativenumber = true
vim.o.scl = "yes"

vim.o.clipboard = "unnamedplus"
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.cursorline = true
vim.o.scrolloff = 8
vim.o.updatetime = 250
vim.o.undofile = true
vim.o.swapfile = false
vim.o.backup = false
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.smartindent = true
vim.o.shiftround = true

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    if vim.v.event.operator == 'y' then
      vim.fn.system('wl-copy', vim.fn.getreg('"'))
    end
    if vim.v.event.operator == 'dd' then
      vim.fn.system('wl-copy', vim.fn.getreg('"'))
    end
  end,
})
