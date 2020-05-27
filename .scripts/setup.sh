#!/bin/sh

# Set timezone
sudo timedatectl set-timezone Europe/London

# Install packages
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get -y install --no-install-recommends ubuntu-desktop virtualbox-guest-dkms
sudo apt-get -y install apt-file devscripts language-pack-en neovim virt-manager ssh-askpass-gnome zsh

# Set locale/language to English (United Kingdom)
sudo update-locale LANG=en_GB.UTF.8

# Configure dotfiles
sudo -u vagrant git clone --bare https://github.com/jmcvaughn/dotfiles.git /home/vagrant/.dotfiles/
sudo -u vagrant git --git-dir=/home/vagrant/.dotfiles/ --work-tree=/home/vagrant/ config core.sparseCheckout true
printf '/*\n!/README.md\n' | sudo -u vagrant tee /home/vagrant/.dotfiles/info/sparse-checkout
sudo -u vagrant git --git-dir=/home/vagrant/.dotfiles/ --work-tree=/home/vagrant/ checkout vagrant-ubuntu-desktop
sudo -u vagrant git --git-dir=/home/vagrant/.dotfiles/ --work-tree=/home/vagrant/ submodule update --init

# Set zsh as default shell
sudo chsh -s /bin/zsh vagrant

# Generate SSH key pair
sudo -u vagrant ssh-keygen -b 4096 -t rsa -N '' -f /home/vagrant/.ssh/id_rsa

# Configure autologin
cat << 'EOF' | sudo tee /etc/gdm3/custom.conf
[daemon]
AutomaticLoginEnable = true
AutomaticLogin = vagrant
EOF

sudo reboot
