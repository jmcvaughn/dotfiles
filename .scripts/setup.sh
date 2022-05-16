#!/bin/sh

# Set variables
. /etc/lsb-release
user=$(getent passwd 1000 | cut -d ':' -f 1)
user_home=$(getent passwd 1000 | cut -d ':' -f 6)

sudo timedatectl set-timezone Europe/London

# Install packages
sudo apt-get update
if grep -q 'vmx' /proc/cpuinfo; then
	sudo apt-get -y install --no-install-recommends virtinst
	libvirt_pkgs='libvirt-clients libvirt-daemon-system ovmf qemu-kvm'
	[ "$DISTRIB_RELEASE" = '16.04' ] && libvirt_pkgs='libvirt-bin ovmf qemu-kvm'
fi
sudo apt-get -y install apt-file bridge-utils default-jre-headless devscripts jq language-pack-en $libvirt_pkgs nfs-common tree zip zsh
for i in nvim; do
	sudo snap install "$i" --classic
done
sudo snap install --channel 18/stable --classic node

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
ubuntu_groups=$(groups ubuntu | tr ' ' ',' | cut -d ',' -f '4-') 2> /dev/null
if [ "$user" != 'ubuntu' ] && [ -n "$ubuntu_groups" ]; then
	sudo usermod --append --groups $ubuntu_groups "$user"
fi

# Generate SSH key pair
sudo -u "$user" ssh-keygen -b 4096 -t rsa -N '' -f "$user_home"/.ssh/id_rsa

echo 'Optional: run `helptags ALL` in nvim to generate helptags'
