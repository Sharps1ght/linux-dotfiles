-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  use {
    'nvim-telescope/telescope.nvim', tag = '*',
    requires = { 'nvim-lua/plenary.nvim' }
  }

  use({
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.tokyonight_style = "night"
    end
  })

  use('theprimeagen/harpoon')
  use('mbbill/undotree')
  use('tpope/vim-fugitive')

  -- LSP
  use 'neovim/nvim-lspconfig'
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'

  -- Completion
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'L3MON4D3/LuaSnip'
  use 'saadparwaiz1/cmp_luasnip'

  -- Treesitter
  use({ 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' })
  use 'nvim-treesitter/nvim-treesitter-textobjects'

  -- UI
  use 'nvim-lualine/lualine.nvim'
  use { 'akinsho/bufferline.nvim', tag = '*', requires = 'nvim-tree/nvim-web-devicons' }
  use 'nvim-tree/nvim-tree.lua'
  use 'lewis6991/gitsigns.nvim'
  use 'lukas-reineke/indent-blankline.nvim'

  -- Editing
  use 'numToStr/Comment.nvim'
  use 'kylechui/nvim-surround'
  use 'windwp/nvim-autopairs'

  -- Navigation
  use 'folke/which-key.nvim'
  use 'folke/persistence.nvim'

end)
