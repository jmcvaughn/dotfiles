#!/bin/sh

user=$(getent passwd 1000 | cut -d ':' -f 1)
user_home=$(getent passwd 1000 | cut -d ':' -f 6)

sudo timedatectl set-timezone Europe/London

sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get -y install --no-install-recommends ubuntu-desktop
sudo apt-get -y install apt-file devscripts language-pack-en neovim virt-manager virt-what ssh-askpass-gnome zsh
if [ "$(sudo virt-what | head -n 1)" = 'virtualbox' ]; then
	sudo apt-get -y install virtualbox-guest-dkms
fi

sudo update-locale LANG=en_GB.UTF.8

# Clone dotfiles
sudo -u "$user" git clone --bare https://github.com/jmcvaughn/dotfiles.git "$user_home"/.dotfiles/
sudo -u "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ config core.sparseCheckout true
printf '/*\n!/README.md\n' | sudo -u "$user" tee "$user_home"/.dotfiles/info/sparse-checkout
sudo -u "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ checkout generic-ubuntu-desktop
sudo -u "$user" git --git-dir="$user_home"/.dotfiles/ --work-tree="$user_home"/ submodule update --init

# Set zsh as default shell
sudo chsh -s /bin/zsh "$user"

# Generate SSH key pair
sudo -u "$user" ssh-keygen -b 4096 -t rsa -N '' -f "$user_home"/.ssh/id_rsa

# Configure auto-login
cat << EOF | sudo tee /etc/gdm3/custom.conf
[daemon]
AutomaticLoginEnable = true
AutomaticLogin = $user
EOF

sudo reboot
