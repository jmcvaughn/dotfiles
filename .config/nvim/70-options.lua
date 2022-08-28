-- Colour scheme
vim.opt.termguicolors = true -- Enable true-colour support
vim.cmd([[colorscheme gruvbox]])

-- Clipboard
---- Should be ignored if clipboard compilation flag not present (e.g.
---- Snap but not Mac)
vim.opt.clipboard = 'unnamedplus'  

-- File saving and undo history
vim.opt.confirm = true
vim.opt.undofile = true

-- Visual guides
vim.opt.colorcolumn = '+1'
vim.opt.cursorline = true  -- Highlight the screen line of the cursor
vim.opt.guicursor = ''
vim.opt.number = true
vim.opt.signcolumn = 'number'
vim.opt.relativenumber = true
vim.opt.ruler = false  -- More detail in Ctrl-G with both this and statusline set

-- Spelling
vim.opt.spelllang = 'en_gb,en_us'

-- Formatting
vim.opt.formatoptions:append('1')  -- Insert line break after one letter word

-- Buffers
vim.opt.hidden = true  -- Hide rather than unload buffers when abandoned

-- Searching
vim.opt.ignorecase = true
vim.opt.showmatch = true
vim.opt.smartcase = true

-- Interface behaviour
vim.opt.cmdheight = 2
vim.opt.mouse = 'a'
vim.opt.scrolloff = 15
vim.opt.shortmess:append('c')
vim.opt.showmode = false
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Directory searching
vim.opt.path:append('**')  -- Add recursive directory searching

-- Wrapping and side scrolling
vim.opt.sidescroll = 10
