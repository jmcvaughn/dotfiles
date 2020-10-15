#!/bin/bash

packages=(
	apparmor-utils
	apt-file
	aria2
	certbot
	devscripts
	docker
	docker-compose
	genisoimage
	ipmitool
	jq
	ksmtuned
	language-pack-en
	libosinfo-bin
	libvirt-clients
	libvirt-daemon-system
	neovim
	nfs-kernel-server
	ovmf
	qemu-kvm
	smartmontools
	source-highlight
	tree
	xkcdpass
	zfsutils-linux
	zip
	znc
	zsh
)

# Set timezone
sudo timedatectl set-timezone Europe/London

# Enable console output
if [ ! -f /etc/default/grub.d/console.cfg ]; then
	echo 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX console=ttyS0"' | sudo tee /etc/default/grub.d/console.cfg
	sudo update-grub
fi

# Install packages
sudo apt-get update
sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt-get update
sudo apt-get -y install --no-install-recommends virtinst
sudo apt-get -y install ${packages[@]}
sudo snap install canonical-livepatch cmadison maas maas-test-db
sudo snap install openstackclients --channel latest/candidate
sudo snap install juju --classic

# Set locale
sudo update-locale LANG=en_GB.UTF-8

# Set shell to Zsh
if [ "$(awk -F ':' "/$USER/ { print \$7 }" /etc/passwd)" != '/bin/zsh' ]; then
	chsh -s /bin/zsh
fi

# Set AppArmor libvirtd profile to complain mode
sudo aa-complain /usr/sbin/libvirtd

# Add maas0 network
sudo virsh net-define "$(dirname "$0")"/maas0.xml
sudo virsh net-autostart maas0
sudo virsh net-start maas0

sudo systemctl enable --now {docker,znc}.service
