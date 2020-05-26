# dotfiles
dotfiles and configuration scripts for all my systems

## Overview
This project is inspired by [StreakyCobra's post on HackerNews](https://news.ycombinator.com/item?id=11071754) and [durdn's tutorial](https://www.atlassian.com/git/tutorials/dotfiles) further outlining the method, with some additions:

- The use of Git submodules for plugins for various applications, negating the need for plugin managers or frameworks
- The use of Git sparse clones to exclude this README from home directories while still keeping it visible on GitHub

## Layout and branches
- The root of every branch maps to the home directory.
- The master branch serves as the base for all other branches, containing dotfiles common to all configurations. These files will not be modified per-branch; any conditional configuration (e.g. per-platform, per-distribution, per-system) will be made in the master branch and evaluated at runtime. An example of this is in .zshrc, where the `os` variable is set and checked to set `PATH`, aliases, etc. This is simply easier to manage.
- Rebasing (`git rebase master`), not merging, is used to update non-master branches.

Any files that aren't dotfiles (such as branch-specific scripts and documentation) are placed in .dotfiles-BRANCH/ (e.g. .dotfiles-mac/).

## Cloning
- Perform a bare clone of the repository:
```
$ git clone --bare git@github.com:jmcvaughn/dotfiles.git $HOME/.dotfiles/
```

- Temporarily create the `dotfiles` alias (this is already defined in .zshrc):
```
$ alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

- Enable sparse checkout and exclude README.md at the root of the repository. Note that while Git 2.25.0 introduced the new `git sparse-checkout` command, the man page states this is currently experimental, so for now this will be configured manually:
```
$ dotfiles config core.sparseCheckout true
$ printf '/*\n!README.md\n' > $HOME/.dotfiles/info/sparse-checkout
$ dotfiles read-tree -mu HEAD
```

- Checkout the desired branch and clone the submodules
```
$ dotfiles checkout mac
$ dotfiles submodule update --init
```

To checkout README.md to modify it:
```
$ printf '/*\n' > $HOME/.dotfiles/info/sparse-checkout
$ dotfiles read-tree -mu HEAD
```
