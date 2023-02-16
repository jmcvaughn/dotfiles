#!/bin/bash

packages=(
	apt-file
	aptly
	aria2
	ceph-base
	devscripts  # Provides rmadison
	docker-ce
	docker-compose-plugin
	gh
	hwloc-nox
	ipmitool
	jq
	ksmtuned
	language-pack-en
	libosinfo-bin
	libvirt-clients
	libvirt-daemon-system
	nfs-kernel-server
	numactl
	ovmf
	python3-pip
	python3-venv
	qemu-kvm
	samba
	smartmontools
	tree
	vagrant
	zfsutils-linux
	zip
	zsh

	# vagrant-libvirt
	libxml2-dev
	libxslt-dev
	ruby-dev
	zlib1g-dev
)

# Set timezone
sudo timedatectl set-timezone Europe/London

# Enable lingering for current user
# Allows user units to run even when the user isn't logged in
sudo loginctl enable-linger "$USER"

# Use the "performance" governor
if [ ! -f /etc/udev/rules.d/10-cpu-scheduler.rules ]; then
	sudo tee /etc/udev/rules.d/10-cpu-scheduler.rules <<- 'EOF'
	KERNEL=="cpu*", ATTR{cpufreq/scaling_governor}="performance"
	EOF
	sudo udevadm trigger
fi

# Disable AppArmor as it interferes with NVMe virtual disks and libvirt, and
# setting libvirtd's profile to "complain" doesn't work either
if [ ! -f /etc/default/grub.d/apparmor_disable.cfg ]; then
	echo 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX apparmor=0"' | sudo tee /etc/default/grub.d/apparmor_disable.cfg
	update_grub=1
fi

sudo apt-get update

# Add repositories
## Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
## GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
## Hashicorp
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Enable deb-src entries (vagrant-libvirt)
sudo sed -i 's|^# deb-src|deb-src|g' /etc/apt/sources.list

# Install packages
sudo apt-get update
sudo apt-get -y install --no-install-recommends virtinst
sudo apt-get -y install ${packages[@]}
sudo apt-get -y build-dep vagrant ruby-libvirt
sudo snap set system experimental.parallel-instances=true
for package in canonical-livepatch; do
	sudo snap install "$package"
done
for package in nvim; do
	sudo snap install "$package" --classic
done
sudo snap install --channel 18/stable --classic node

# Install Vagrant plugins
vagrant plugin install vagrant-libvirt vagrant-scp

# Create Intel One Boot Flash Update (OFU) symlink
sudo ln -s /usr/bin/flashupdt/flashupdt /usr/local/sbin/

# Set locale
sudo update-locale LANG=en_GB.UTF-8

# Set shell to Zsh
if [ "$(awk -F ':' "/$USER/ { print \$7 }" /etc/passwd)" != '/bin/zsh' ]; then
	chsh -s /bin/zsh
fi

# Add default-hdd pool
if ! sudo virsh pool-list --all --name | grep -q default-hdd; then
	sudo virsh pool-define "$(dirname "$0")"/default-hdd.xml
	sudo virsh pool-autostart default-hdd
	sudo virsh pool-start default-hdd
fi

# Configure libvirt-guests
if ! grep -qE '^ON_BOOT=start$' /etc/default/libvirt-guests; then
	sudo sed -i '/^#ON_BOOT=ignore$/ a ON_BOOT=start' /etc/default/libvirt-guests
fi
if ! grep -qE '^START_DELAY=5$' /etc/default/libvirt-guests; then
	sudo sed -i '/^#START_DELAY=0$/ a START_DELAY=5' /etc/default/libvirt-guests
fi

# Increase swap
if ! swapon -s | grep -q '/swap2.img'; then
	sudo dd if=/dev/zero of=/swap2.img bs=1G count=16 conv=fsync status=progress
	sudo chmod 0600 /swap2.img
	sudo mkswap /swap2.img
	sudo swapon /swap2.img
	if ! grep -qE '^/swap2.img' /etc/fstab; then
		sudo tee -a /etc/fstab <<- 'EOF'
		/swap2.img	none	swap	sw	0	0
		EOF
	fi
fi

# Disable password authentication for SSH
if [ ! -f /etc/ssh/sshd_config.d/password_auth.conf ]; then
	sudo tee /etc/ssh/sshd_config.d/password_auth.conf <<- 'EOF'
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

# Disable I/O scheduler for ZFS vdevs
if [ ! -f /etc/udev/rules.d/95-zfs-none-scheduler.rules ]; then
	sudo tee /etc/udev/rules.d/95-zfs-none-scheduler.rules <<- 'EOF'
	ENV{ID_FS_TYPE}=="zfs_member", ATTR{../queue/scheduler}="none"
	EOF
	sudo udevadm trigger
fi

# Set Samba password for current user
if ! sudo smbpasswd -e "$USER"; then
	sudo smbpasswd -a "$USER"
	sudo systemctl restart smbd.service
	sudo systemctl enable smbd.service
fi

# Add current user to docker group
sudo usermod -aG docker "$USER"

# Enable passwordless sudo for current user
if sudo [ ! -f /etc/sudoers.d/"$USER" ]; then
	sudo tee /etc/sudoers.d/"$USER" <<- EOF
	$USER ALL = (ALL) NOPASSWD: ALL
	EOF
	sudo chmod 0440 /etc/sudoers.d/"$USER"
fi

[ "${systemd_reload:-0}" -eq 1 ] && sudo systemctl daemon-reload
sudo systemctl enable --now zfs-trim.timer

if ! systemctl --user is-enabled update-cloud-images.timer > /dev/null; then
	systemctl --user daemon-reload
	systemctl --user enable update-cloud-images.timer
fi
if ! systemctl --user is-enabled update-vagrant-boxes.timer > /dev/null; then
	systemctl --user daemon-reload
	systemctl --user enable update-vagrant-boxes.timer
fi

[ "${update_grub:-0}" -eq 1 ] && sudo update-grub
