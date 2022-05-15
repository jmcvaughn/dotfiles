#!/bin/bash

# Set variables
. /etc/lsb-release

sudo timedatectl set-timezone Europe/London

# Install packages
sudo apt-get update
sudo apt-get -y install apt-file curl default-jre-headless devscripts jq language-pack-en nfs-common openssh-server ssh-askpass-gnome tree virt-manager virt-what zip zsh
hypervisor=$(sudo virt-what | head -n 1)
case $hypervisor in
	'vmware') sudo apt-get -y install open-vm-tools-desktop ;;
	'virtualbox') sudo apt-get -y install virtualbox-guest-dkms ;;
esac
for i in batcat nvim; do
	sudo snap install "$i" --classic
done
sudo snap install --channel 18/stable --classic node

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

echo 'Optional: run `helptags ALL` in nvim to generate helptags'
