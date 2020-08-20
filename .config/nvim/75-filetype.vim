" Default
setfiletype text

" Configuration files
autocmd FileType sshconfig set expandtab shiftwidth=0 tabstop=2

" Data serialisation
autocmd FileType yaml set shiftwidth=0 tabstop=2 spell nowrap

" Programming languages
autocmd FileType awk set shiftwidth=0 tabstop=2 nowrap
autocmd FileType python set shiftwidth=0 tabstop=4 textwidth=79 nowrap
autocmd FileType sh,bash,zsh set shiftwidth=0 tabstop=2 nowrap
autocmd FileType vim set expandtab shiftwidth=0 tabstop=2 nowrap

" LaTeX
autocmd FileType bib,tex set expandtab shiftwidth=0 tabstop=2 spell

" Other written language
autocmd FileType gitcommit set expandtab shiftwidth=0 tabstop=2 spell
autocmd FileType markdown set expandtab shiftwidth=0 tabstop=4 spell
autocmd FileType text set expandtab shiftwidth=0 tabstop=2 spell
