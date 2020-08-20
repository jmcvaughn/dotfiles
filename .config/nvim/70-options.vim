" Colour scheme
set termguicolors  " Enable true-colour support
colorscheme gruvbox

" File saving and undo history
set confirm
set undofile

" Visual guides
set colorcolumn=+1
set cursorline  " Highlight the screen line of the cursor
set guicursor=
set number
set signcolumn=number
set relativenumber
set noruler  " More detail in Ctrl-G with both this and statusline set

" Spelling
set spelllang=en_gb,en_us

" Formatting
set formatoptions+=1  " Insert line break after one letter word

" Buffers
set hidden  " Hide rather than unload buffers when abandoned

" Searching
set ignorecase
set showmatch
set smartcase

" Interface behaviour
set mouse=a
set scrolloff=15
set noshowmode
set splitbelow
set splitright

" Directory searching
set path+=**  " Add recursive directory searching

" Wrapping and side scrolling
set sidescroll=10

" Status line
set statusline=Col:\ %v  " Column
set statusline+=\ \   " 2 spaces
set statusline+=Mode:\ %{mode()}  " Mode
set statusline+=%=  " Right-justify
set statusline+=%.40f\   " Relative path
set statusline+=%m  " Modified flag: [+], [-]
set statusline+=%r  " Read-only flag: [RO]
set statusline+=%y  " Filetype: [filetype]
