#!/bin/sh

# Set variables
. /etc/lsb-release
user=$(getent passwd 1000 | cut -d ':' -f 1)
user_home=$(getent passwd 1000 | cut -d ':' -f 6)

sudo timedatectl set-timezone Europe/London

# Neovim
sudo apt-get update
sudo add-apt-repository -y ppa:neovim-ppa/unstable

sudo apt-get update
sudo apt-get -y install --no-install-recommends ubuntu-desktop
sudo apt-get -y install apt-file devscripts jq language-pack-en neovim nfs-common source-highlight ssh-askpass-gnome tree virt-manager virt-what zip zsh
hypervisor=$(sudo virt-what | head -n 1)
case $hypervisor in
	'vmware') sudo apt-get -y install open-vm-tools-desktop ;;
	'virtualbox') sudo apt-get -y install virtualbox-guest-dkms ;;
esac

sudo update-locale LANG=en_GB.UTF-8

# Clone dotfiles
sudo -u "$user" git clone --bare https://github.com/jmcvaughn/dotfiles.git "$user_home"/.dotfiles/
sudo -u "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ config core.sparseCheckout true
printf '/*\n!/README.md\n' | sudo -u "$user" tee "$user_home"/.dotfiles/info/sparse-checkout
sudo -u "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ checkout generic-ubuntu-desktop
## Login shell (`-i`) required, otherwise the following error occurs:
## fatal: /usr/lib/git-core/git-submodule cannot be used without a working tree.
## Vagrant runs scripts as UID 1000 with sudo so it doesn't require `-i`
sudo -iu "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ submodule update --init --recursive --jobs 4

# Set zsh as default shell
sudo chsh -s /bin/zsh "$user"

# Add this user to the same groups as "ubuntu" user, if it exists
ubuntu_groups=$(groups ubuntu | tr ' ' ',' | cut -d ',' -f '4-') 2> /dev/null
if [ "$user" != 'ubuntu' ] && [ -n "$ubuntu_groups" ]; then
	sudo usermod --append --groups $ubuntu_groups "$user"
fi

# Generate SSH key pair
sudo -u "$user" ssh-keygen -b 4096 -t rsa -N '' -f "$user_home"/.ssh/id_rsa

# Configure auto-login
cat << EOF | sudo tee /etc/gdm3/custom.conf
[daemon]
AutomaticLoginEnable = true
AutomaticLogin = $user
EOF
