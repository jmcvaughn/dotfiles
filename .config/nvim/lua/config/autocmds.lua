-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Default to "text" filetype
vim.bo.filetype = "text"

-- Configuration files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "sshconfig",
  command = "set expandtab shiftwidth=0 tabstop=2",
})

-- Data serialisation
vim.api.nvim_create_autocmd("FileType", {
  pattern = "json",
  command = "set expandtab shiftwidth=0 tabstop=2 nowrap",
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "yaml",
  command = "set shiftwidth=0 tabstop=2 nowrap",
})

-- Programming languages
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "awk", "sh", "bash", "zsh" },
  command = "set shiftwidth=0 tabstop=2 nowrap",
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua", "vim" },
  command = "set expandtab shiftwidth=0 tabstop=2 nowrap",
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  command = "set shiftwidth=0 tabstop=4 textwidth=88 nowrap",
})

-- LaTeX
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "bib", "tex" },
  command = "set expandtab shiftwidth=0 spell tabstop=2",
})

-- Other written language
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gitcommit", "markdown", "text" },
  command = "set expandtab shiftwidth=0 spell tabstop=2",
})
