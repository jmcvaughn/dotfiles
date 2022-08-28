vim.cmd([[
  for file in split(glob('~/.config/nvim/*-*.lua'))
    execute 'source ' . file
  endfor
]])
