-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Insert, Meta-Backspace to delete word (Emacs/Mac)
vim.keymap.set("i", "<M-BS>", "<C-w>")
