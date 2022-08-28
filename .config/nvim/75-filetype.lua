-- Default
vim.bo.filetype = 'text'

-- Configuration files
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'sshconfig',
  command = 'set expandtab shiftwidth=0 tabstop=2',
})

-- Data serialisation
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'json',
  command = 'set expandtab shiftwidth=0 tabstop=2 spell nowrap',
})
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'yaml',
  command = 'set shiftwidth=0 tabstop=2 spell nowrap',
})

-- Programming languages
vim.api.nvim_create_autocmd('FileType', {
  pattern = {'awk', 'sh', 'bash', 'zsh'},
  command = 'set shiftwidth=0 tabstop=2 nowrap',
})
vim.api.nvim_create_autocmd('FileType', {
  pattern = {'lua', 'vim'},
  command = 'set expandtab shiftwidth=0 tabstop=2 nowrap',
})
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  command = 'set shiftwidth=0 tabstop=4 textwidth=79 nowrap',
})

-- LaTeX
vim.api.nvim_create_autocmd('FileType', {
  pattern = {'bib', 'tex'},
  command = 'set expandtab shiftwidth=0 tabstop=2 spell',
})

-- Other written language
vim.api.nvim_create_autocmd('FileType', {
  pattern = {'gitcommit', 'markdown', 'text'},
  command = 'set expandtab shiftwidth=0 tabstop=2 spell',
})
