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
	python3-heatclient
	python3-neutronclient
	python3-openstackclient
	python3-swiftclient
	qemu-kvm
	samba
	smartmontools
	sysstat
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
for i in batcat juju; do
	sudo snap install "$i" --classic
done

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

# Create ZFS TRIM script
[ ! -f /usr/local/sbin/zfs-trim ] && sudo tee /usr/local/sbin/zfs-trim << 'EOF'
#!/bin/sh

# Will TRIM all pools, with those that don't support TRIM being silently
# ignored by ZFS. Otherwise, only TRIM pools with autotrim enabled.
trim_all_pools=1

zpools=$(zpool list -Ho name)
if [ "${trim_all_pools:-0}" -eq 1 ]; then
	for zpool in $zpools; do
		zpool trim "$zpool"
	done
else
	for zpool in $zpools; do
		[ "$(zpool get -Ho value autotrim "$zpool")" = 'on' ] && zpool trim "$zpool"
	done
fi
EOF
sudo chmod 0755 /usr/local/sbin/zfs-trim

# Service to run the above script
if [ ! -f /etc/systemd/system/zfs-trim.service ]; then
	sudo tee /etc/systemd/system/zfs-trim.service <<- 'EOF'
	[Unit]
	Description=Trim ZFS pools
	Requisite=zfs.target
	After=zfs.target

	[Service]
	Type=oneshot
	ExecStart=/usr/local/sbin/zfs-trim
	EOF
	systemd_reload=1
fi

# Timer to run the above service every Sunday at 3:30am
if [ ! -f /etc/systemd/system/zfs-trim.timer ]; then
	sudo tee /etc/systemd/system/zfs-trim.timer <<- 'EOF'
	[Unit]
	Description=Trim ZFS pools periodically

	[Timer]
	OnCalendar=Sun *-*-* 03:30:00
	Unit=zfs-trim.service
	Persistent=true

	[Install]
	WantedBy=timers.target
	EOF
	systemd_reload=1
fi

# Set Samba password for current user
sudo mkdir /var/lib/samba/private/
[ ! -f /var/lib/samba/private/passdb.tdb ] && sudo smbpasswd -a "$USER"

[ "${systemd_reload:-0}" -eq 1 ] && sudo systemctl daemon-reload
sudo systemctl enable --now {docker,smbd,znc}.service zfs-trim.timer
