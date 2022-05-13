#!/bin/bash

packages=(
	apt-file
	aria2
	bzr
	ceph-base
	default-jre-headless
	devscripts
	fio
	genisoimage
	gh
	git-review
	iotop
	ipmitool
	jq
	ksmtuned
	language-pack-en
	libosinfo-bin
	libvirt-clients
	libvirt-daemon-system
	lnav
	mongo-tools
	nfs-kernel-server
	ovmf
	packer
	pylint
	python-six
	python3-dev
	python3-keystoneclient
	python3-neutronclient
	qemu-kvm
	samba
	smartmontools
	sysstat
	tox
	tree
	xkcdpass
	zfsutils-linux
	zip
	zsh
)

# Set timezone
sudo timedatectl set-timezone Europe/London

# Use the "performance" governor
echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
sudo systemctl disable ondemand.service

# Enable console output
if [ ! -f /etc/default/grub.d/console.cfg ]; then
	echo 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX console=ttyS0"' | sudo tee /etc/default/grub.d/console.cfg
	update_grub=1
fi

# Set rootdelay due to SATA initialisation delay
if [ ! -f /etc/default/grub.d/rootdelay.cfg ]; then
	echo 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX rootdelay=60"' | sudo tee /etc/default/grub.d/rootdelay.cfg
	update_grub=1
fi

sudo apt-get update

# Add repositories
## HashiCorp
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
## GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Install packages
sudo apt-get update
sudo apt-get -y install --no-install-recommends gnuplot virtinst
sudo apt-get -y install ${packages[@]}
sudo snap set system experimental.parallel-instances=true
sudo snap install canonical-livepatch cmadison docker hotsos maas maas-test-db openstackclients ovs-stat vault
for i in batcat charm charmcraft juju kubectl nvim; do
	sudo snap install "$i" --classic
done
sudo snap install --channel 18/stable --classic node
sudo snap connect ovs-stat:removable-media  # See https://snapcraft.io/ovs-stat

# Create Intel One Boot Flash Update (OFU) symlink
sudo ln -s /usr/bin/flashupdt/flashupdt /usr/local/sbin/

# Set locale
sudo update-locale LANG=en_GB.UTF-8

# Set shell to Zsh
if [ "$(awk -F ':' "/$USER/ { print \$7 }" /etc/passwd)" != '/bin/zsh' ]; then
	chsh -s /bin/zsh
fi

# Configure libvirt-guests
if [ ! -f /etc/default/libvirt-guests.bak ]; then
	sudo mv /etc/default/libvirt-guests{,.bak}
	sudo tee /etc/default/libvirt-guests <<- 'EOF'
	# See /etc/default/libvirt-guests.bak for documentation and defaults
	# See /usr/lib/libvirt/libvirt-guests.sh for script defaults

	ON_BOOT=start
	PARALLEL_SHUTDOWN=10
	START_DELAY=5
	EOF
fi

# Add maas0 network
if ! sudo virsh net-list --all --name | grep -q maas0; then
	sudo virsh net-define "$(dirname "$0")"/maas0.xml
	sudo virsh net-autostart maas0
	sudo virsh net-start maas0
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
sudo mkdir /var/lib/samba/private/
[ ! -f /var/lib/samba/private/passdb.tdb ] && sudo smbpasswd -a "$USER"

[ "${systemd_reload:-0}" -eq 1 ] && sudo systemctl daemon-reload
sudo systemctl enable --now smbd.service zfs-trim.timer
[ "${update_grub:-0}" -eq 1 ] && sudo update-grub
