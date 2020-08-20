for file in split(glob('~/.config/nvim/*-*.vim'))
  execute 'source ' . file
endfor
