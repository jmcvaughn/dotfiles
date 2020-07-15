#!/bin/sh

# Set variables
. /etc/lsb-release
user=$(getent passwd 1000 | cut -d ':' -f 1)
user_home=$(getent passwd 1000 | cut -d ':' -f 6)

sudo timedatectl set-timezone Europe/London

if [ "$DISTRIB_RELEASE" = '16.04' ] || [ "$DISTRIB_RELEASE" = '18.04' ]; then
	sudo apt-get update
	sudo add-apt-repository -y ppa:neovim-ppa/unstable
fi
sudo apt-get update
sudo apt-get -y upgrade
libvirt_pkgs='libvirt-clients libvirt-daemon-system'
[ "$DISTRIB_RELEASE" = '16.04' ] && libvirt_pkgs='libvirt-bin'
sudo apt-get -y install apt-file aria2 bridge-utils devscripts jq language-pack-en $libvirt_pkgs neovim nfs-common qemu-kvm source-highlight tree zip zsh
sudo apt-get -y install --no-install-recommends virtinst

sudo update-locale LANG=en_GB.UTF-8

# Clone dotfiles
sudo -u "$user" git clone --bare https://github.com/jmcvaughn/dotfiles.git "$user_home"/.dotfiles/
sudo -u "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ config core.sparseCheckout true
printf '/*\n!/README.md\n' | sudo -u "$user" tee "$user_home"/.dotfiles/info/sparse-checkout
sudo -u "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ checkout generic-ubuntu-server
## Login shell (`-i`) required, otherwise the following error occurs:
## fatal: /usr/lib/git-core/git-submodule cannot be used without a working tree.
## Vagrant runs scripts as UID 1000 with sudo so it doesn't require `-i`
if [ "$DISTRIB_RELEASE" = '16.04' ]; then
	sudo -iu "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ submodule update --init --recursive
else
	sudo -iu "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ submodule update --init --recursive --jobs 4
fi

# Set zsh as default shell
sudo chsh -s /bin/zsh "$user"

# Add this user to the same groups as "ubuntu" user, if it exists
if [ "$user" != 'ubuntu' ] && ubuntu_groups=$(groups ubuntu | tr ' ' ',' | cut -d ',' -f '4-') > /dev/null 2>&1; then
	sudo usermod --append --groups $ubuntu_groups "$user"
fi

# Generate SSH key pair
sudo -u "$user" ssh-keygen -b 4096 -t rsa -N '' -f "$user_home"/.ssh/id_rsa

sudo reboot
