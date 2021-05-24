# git: list of 3-tuples of URL, branch, directory
# neovim: list of 3-tuples of url, branch, and whether `yarn install` required
# zsh: list of 2-tuples of URL and branch
git = [
        ('https://github.com/bswinnerton/launchbar-github', 'master',
        '~/Library/Application Support/LaunchBar/Actions/github.lbaction'),
        ('https://github.com/jmcvaughn/less_app', 'master', '~/git/less_app/')
]

neovim = [
        ('https://github.com/neoclide/coc.nvim', 'release', False),
        ('https://github.com/morhetz/gruvbox', 'master', False),
        ('https://github.com/iamcco/markdown-preview.nvim', 'master', True),
        ('https://github.com/tomtom/tcomment_vim', 'master', False),
        ('https://github.com/rbong/vim-crystalline', 'master', False),
        ('https://github.com/tpope/vim-fugitive', 'master', False),
        ('https://github.com/tpope/vim-unimpaired', 'master', False)
]

zsh = [
        ('https://github.com/zsh-users/zsh-autosuggestions', 'master'),
        ('https://github.com/zsh-users/zsh-completions', 'master'),
        ('https://github.com/zsh-users/zsh-history-substring-search',
            'master'),
        ('https://github.com/zsh-users/zsh-syntax-highlighting', 'master')
]
