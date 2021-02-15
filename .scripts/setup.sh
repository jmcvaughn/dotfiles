#!/bin/bash

# Set variables
. /etc/lsb-release

sudo timedatectl set-timezone Europe/London

sudo apt-get update

# Add repositories
## Neovim
sudo add-apt-repository -y ppa:neovim-ppa/unstable
## Node.js and Yarn
if [ "${DISTRIB_RELEASE%.*}" -le 18 ]; then
	curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
fi

sudo apt-get update
[ "${DISTRIB_RELEASE%.*}" -ge 20 ] && yarn_pkg='yarnpkg' || yarn_pkg='yarn'
sudo apt-get -y install apt-file default-jre-headless devscripts jq language-pack-en neovim nfs-common nodejs openssh-server ssh-askpass-gnome tree virt-manager virt-what "$yarn_pkg" zip zsh
hypervisor=$(sudo virt-what | head -n 1)
case $hypervisor in
	'vmware') sudo apt-get -y install open-vm-tools-desktop ;;
	'virtualbox') sudo apt-get -y install virtualbox-guest-dkms ;;
esac
sudo snap install batcat --classic

sudo update-locale LANG=en_GB.UTF-8

# Clone dotfiles
git clone --bare https://github.com/jmcvaughn/dotfiles.git "$HOME"/.dotfiles/
git --git-dir="$HOME"/.dotfiles/ --work-tree="$HOME" config core.sparseCheckout true
printf '/*\n!/README.md\n' | tee "$HOME"/.dotfiles/info/sparse-checkout
git --git-dir="$HOME"/.dotfiles/ --work-tree="$HOME" checkout generic-ubuntu-desktop
git --git-dir="$HOME"/.dotfiles/ --work-tree="$HOME" submodule update --init --recursive --jobs 4

# Set zsh as default shell
[[ "$SHELL" != *'zsh' ]] && chsh -s /bin/zsh

# Generate SSH key pair
ssh-keygen -b 4096 -t rsa -N '' -f "$HOME"/.ssh/id_rsa

echo 'Optional: run ~/.scripts/nvim.sh to generate helptags'
