# dotfiles
dotfiles and configuration scripts for all my systems

## Overview
This project is inspired by [StreakyCobra's post on HackerNews](https://news.ycombinator.com/item?id=11071754) and [durdn's tutorial](https://www.atlassian.com/git/tutorials/dotfiles) further outlining the method. The only change is the use of Git sparse clones to exclude this README from home directories while still keeping it visible on GitHub.

## Layout and branches
- The root of every branch maps to the home directory.
- The master branch serves as the base for all other branches, containing dotfiles common to all configurations. These files will not be modified per-branch; any conditional configuration (e.g. per-platform, per-distribution, per-system) will be made in the master branch and evaluated at runtime. An example of this is in .zshrc, where the `os` variable is set and checked to set `PATH`, aliases, etc. This is simply easier to manage.
- Rebasing (`git rebase master`), not merging, is used to update non-master branches.

In non-master branches, any additional setup scripts can be found in .scripts/ and any documentation can be found in .docs/. Refer to this documentation **before** cloning for any additional tasks required before cloning or for otherwise setting up a system.

**WARNING: Never use `dotfiles clean`/`git clean` on this repository.** Doing so will result in files in your home directory being deleted. While it is possible to provide *some* level of safety by using a .gitignore for all files, this means `dotfiles status` will files that haven't been added (which is often convenient). Git does not provide a way to alias over a built-in, so `dotfiles config alias.clean 'noop'` will not work. Prioritising safety over convenience might seem like a bad compromise, but simply remembering to not use `clean` is straightforward enough. You have been warned.

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
$ printf '/*\n!/README.md\n' > $HOME/.dotfiles/info/sparse-checkout
$ dotfiles read-tree -mu HEAD
```

- Checkout the desired branch
```
$ dotfiles checkout mac
```

To checkout README.md to modify it:
```
$ printf '/*\n' > $HOME/.dotfiles/info/sparse-checkout
$ dotfiles read-tree -mu HEAD
```
