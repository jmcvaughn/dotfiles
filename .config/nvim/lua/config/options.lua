-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- LazyVim options
vim.g.autoformat = false
vim.g.snacks_animate_scroll = false

-- Neovim options
vim.opt.colorcolumn = "+1"
vim.opt.formatoptions:append("1") -- Insert line break after one letter word
vim.opt.guicursor = "" -- Block cursor
vim.opt.path:append("**") -- Add recursive directory searching
vim.opt.scrolloff = 15 -- Ensure 15 lines above/below cursor where possible

---- Reset to defaults
vim.opt.expandtab = false
vim.opt.shiftwidth = 8
vim.opt.tabstop = 8

-- Disable diagnostics by default
-- vim.diagnostic.enable(false)

-- Text options
vim.opt.modelines = 1
vim.opt.textwidth = 80

-- LSP
vim.g.lazyvim_python_lsp = "basedpyright"
