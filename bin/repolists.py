# git: list of 4-tuples of URL, branch, directory, list of 2-tuples of remotes
# images: list of URLs
# neovim: list of 3-tuples of url, branch, and whether `yarn install` required
# yarn: list of packages
# zsh: list of 2-tuples of URL and branch
git = [
    ('https://github.com/bswinnerton/launchbar-github', 'master',
        '~/Library/Application Support/LaunchBar/Actions/github.lbaction'),
    ('https://github.com/jmcvaughn/less_app', 'master', '~/git/less_app/')
]

neovim = [
    ('https://github.com/iamcco/markdown-preview.nvim', 'master', True),
]

zsh = [
    ('https://github.com/zsh-users/zsh-autosuggestions', 'master'),
    ('https://github.com/zsh-users/zsh-completions', 'master'),
    ('https://github.com/zsh-users/zsh-history-substring-search', 'master'),
    ('https://github.com/zsh-users/zsh-syntax-highlighting', 'master')
]
