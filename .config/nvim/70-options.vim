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
if has('nvim-0.5')
  set signcolumn=number
else
  set signcolumn=yes
endif
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
set cmdheight=2
set mouse=a
set scrolloff=15
set shortmess+=c
set noshowmode
set splitbelow
set splitright

" Directory searching
set path+=**  " Add recursive directory searching

" Wrapping and side scrolling
set sidescroll=10
