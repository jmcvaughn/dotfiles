#!/bin/bash

packages=(
	apparmor-utils
	apt-file
	aria2
	certbot
	default-jre-headless
	devscripts
	docker
	docker-compose
	fio
	genisoimage
	iotop
	ipmitool
	jq
	ksmtuned
	language-pack-en
	libosinfo-bin
	libvirt-clients
	libvirt-daemon-system
	mongo-tools
	neovim
	nfs-kernel-server
	nodejs
	ovmf
	python-six
	python3-neutronclient
	python3-openstackclient
	qemu-kvm
	smartmontools
	tree
	xkcdpass
	yarnpkg
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
sudo apt-get -y install --no-install-recommends gnuplot virtinst
sudo apt-get -y install ${packages[@]}
sudo snap install canonical-livepatch cmadison maas maas-test-db vault
sudo snap install batcat juju --classic

# Create Intel One Boot Flash Update (OFU) symlink
sudo ln -s /usr/bin/flashupdt/flashupdt /usr/local/sbin/

# Set locale
sudo update-locale LANG=en_GB.UTF-8

# Set shell to Zsh
if [ "$(awk -F ':' "/$USER/ { print \$7 }" /etc/passwd)" != '/bin/zsh' ]; then
	chsh -s /bin/zsh
fi

# Set AppArmor libvirtd profile to complain mode
sudo aa-complain /usr/sbin/libvirtd

# Add maas0 network
if ! sudo virsh net-list --all --name | grep -q maas0; then
	sudo virsh net-define "$(dirname "$0")"/maas0.xml
	sudo virsh net-autostart maas0
	sudo virsh net-start maas0
fi

# Add srv-libvirt-images storage pool
## MongoDB seems very sensitive to I/O, so we place this on the root (/) SSD
## array
if ! sudo virsh pool-list --all --name | grep -q srv-libvirt-images; then
	sudo mkdir /srv/libvirt-images/
	sudo virsh pool-define "$(dirname "$0")"/srv-libvirt-images.xml
	sudo virsh pool-autostart srv-libvirt-images
	sudo virsh pool-start srv-libvirt-images
fi

# Configure libvirt-guests
if ! grep -qE '^ON_BOOT=start$' /etc/default/libvirt-guests; then
	sudo sed -i '/^#ON_BOOT=ignore$/ a ON_BOOT=start' /etc/default/libvirt-guests
fi
if ! grep -qE '^ON_SHUTDOWN=suspend$' /etc/default/libvirt-guests; then
	sudo sed -i '/^#ON_SHUTDOWN=shutdown$/ a ON_SHUTDOWN=suspend' /etc/default/libvirt-guests
fi

# Increase swap
if ! swapon -s | grep -q '/swap2.img'; then
	sudo dd if=/dev/zero of=/swap2.img bs=1G count=16 conv=fsync status=progress
	sudo chmod 0600 /swap2.img
	sudo mkswap /swap2.img
	sudo swapon /swap2.img
	if ! grep -qE '^/swap2.img' /etc/fstab; then
		cat <<- 'EOF' | sudo tee -a /etc/fstab
		/swap2.img	none	swap	sw	0	0
		EOF
	fi
fi

# Disable password authentication for SSH
if [ ! -f /etc/ssh/sshd_config.d/password_auth.conf ]; then
	cat <<- 'EOF' | sudo tee /etc/ssh/sshd_config.d/password_auth.conf
	PasswordAuthentication no
	EOF
	sudo systemctl restart sshd.service
fi

sudo systemctl enable --now {docker,znc}.service
