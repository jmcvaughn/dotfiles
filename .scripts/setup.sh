#!/bin/sh

# Set variables
. /etc/lsb-release
user=$(getent passwd 1000 | cut -d ':' -f 1)
user_home=$(getent passwd 1000 | cut -d ':' -f 6)

sudo timedatectl set-timezone Europe/London

if [ "$DISTRIB_RELEASE" = '16.04' ]; then
	sudo apt-get update
	sudo add-apt-repository -y ppa:neovim-ppa/stable
fi
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get -y install apt-file devscripts language-pack-en neovim zsh

sudo update-locale LANG=en_GB.UTF.8

# Clone dotfiles
sudo -u "$user" git clone --bare https://github.com/jmcvaughn/dotfiles.git "$user_home"/.dotfiles/
sudo -u "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ config core.sparseCheckout true
printf '/*\n!/README.md\n' | sudo -u "$user" tee "$user_home"/.dotfiles/info/sparse-checkout
sudo -u "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ checkout generic-ubuntu-server
sudo -u "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ submodule update --init

# Set zsh as default shell
sudo chsh -s /bin/zsh "$user"

# Generate SSH key pair
sudo -u "$user" ssh-keygen -b 4096 -t rsa -N '' -f "$user_home"/.ssh/id_rsa

sudo reboot
