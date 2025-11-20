#!/bin/bash

domain=''
duckdns_token=''
lan_interface='eno1'
subnets=''
wan_interface='enp2s0'
ha_port=''

# WireGuard (remote access)
wg0_port=''
wg0_address=''  # Without subnet mask or CIDR

# WireGuard (outward tunnel)
wg1_peer=''
wg1_address=''

packages=(
	apt-file
	aria2
	bluez
	default-jre-headless
	devscripts  # Provides rmadison
	dnscrypt-proxy
	dnsmasq
	docker-ce
	docker-compose-plugin
	iperf
	ipmitool
	iptables-persistent
	jq
	ksmtuned
	language-pack-en
	net-tools
	nfs-common
	npm
	pppoeconf
	python3-venv
	python3-intelhex  # For Zigbee dongle firmware updates
	smartmontools
	speedtest-cli
	tree
	wireguard
	zip
	zsh
)

lan_address=$(ip a show dev "$lan_interface" | awk '/inet / { print $2 }')
wg1_peer_shortname=${wg1_peer%%.*}

sudo systemctl disable --now {systemd-resolved,ufw}.service
sudo systemctl mask {systemd-resolved,ufw}.service

# Create pppd service
if [ ! -f /etc/systemd/system/pppd@.service ]; then
	cat <<- 'EOF' | sudo tee /etc/systemd/system/pppd@.service
	[Unit]
	Description=PPP link to %i
	Before=network.target

	[Service]
	Type=notify
	ExecStart=/usr/sbin/pppd call %i nodetach nolog up_sdnotify

	[Install]
	WantedBy=multi-user.target
	EOF
	sudo systemctl daemon-reload
	sudo systemctl enable pppd@dsl-provider.service
fi

# Enable forwarding
if [ ! -f /etc/sysctl.d/99-z-forwarding.conf ]; then
	echo 'net.ipv4.conf.all.forwarding = 1' | sudo tee /etc/sysctl.d/99-z-forwarding.conf
	sudo sysctl -p /etc/sysctl.d/99-z-forwarding.conf
fi

# Enable discard for the root ('/') file system, remount
rootfs_uuid=$(lsblk -lno mountpoint,uuid | awk '$1 == "/" { print $2 }')
if ! grep -E "^[^#].*$rootfs_uuid.+discard" /etc/fstab; then
	sudo sed -i "/$rootfs_uuid/ s/defaults/defaults,discard/" /etc/fstab
	sudo mount -o remount /
fi

for count in {1..5}; do
	ping -c 1 1.1.1.1 && break || sleep 5
	[ "$count" = 5 ] && >&2 echo 'No Internet connection detected' && exit 1
done

# If nameserver hasn't been set to localhost, presume first install
if ! grep -q 'nameserver 127.0.0.1' /etc/resolv.conf; then
	sudo rm /etc/resolv.conf
	echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf
fi

# Set timezone
sudo timedatectl set-timezone Europe/London

# Use the "performance" governor
if [ ! -f /etc/udev/rules.d/10-cpu-scheduler.rules ]; then
	sudo tee /etc/udev/rules.d/10-cpu-scheduler.rules <<- 'EOF'
	KERNEL=="cpu*", ATTR{cpufreq/scaling_governor}="performance"
	EOF
	sudo udevadm trigger
fi

sudo apt-get update

# Add repositories
## Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

# Install packages
sudo apt-get update
sudo apt-get -y install ${packages[@]}
for i in canonical-livepatch; do
	sudo snap install "$i"
done
for i in certbot nvim; do
	sudo snap install "$i" --classic
done
# sudo snap install --channel 18/stable --classic node

# Set locale
sudo update-locale LANG=en_GB.UTF-8

# Configure dnsmasq to use dnscrypt-proxy for resolution
if [ ! -f /etc/dnsmasq.d/jmcvaughn-dotfiles ]; then
	sudo tee /etc/dnsmasq.d/jmcvaughn-dotfiles <<- 'EOF'
	# Redirect everything to dnscrypt-proxy
	listen-address = 127.0.0.1  # Required as dnscrypt-proxy also listens on lo
	bind-interfaces
	no-resolv
	server = 127.0.2.1
	cache-size = 0  # dnscrypt-proxy caches
	conf-file = /usr/share/dnsmasq-base/trust-anchors.conf
	EOF
	sudo systemctl restart dnsmasq.service
fi

# Move to local nameserver now that dnsmasq is running
if ! grep -q "nameserver ${lan_address%/*}" /etc/resolv.conf; then
	sudo tee /etc/resolv.conf <<- EOF
	nameserver ${lan_address%/*}
	search $domain
	EOF
fi

# Import jmcvaughn SSH keys
## Empty authorized_keys exists by default
if ! grep -q 'jmcvaughn' "$HOME"/.ssh/authorized_keys; then
	ssh-import-id gh:jmcvaughn
fi

# Disable password authentication for SSH
if [ ! -f /etc/ssh/sshd_config.d/password_auth.conf ]; then
	sudo tee /etc/ssh/sshd_config.d/password_auth.conf <<- 'EOF'
	PasswordAuthentication no
	EOF
	sudo systemctl restart sshd.service
fi

# Create dynamic DNS service
if [ ! -f /etc/systemd/system/dynamic-dns.service ]; then
	sudo tee /etc/systemd/system/dynamic-dns.service <<- EOF
	[Unit]
	Description=Update dynamic DNS entry
	After=multi-user.target
	[Service]
	ExecStart=curl -k https://www.duckdns.org/update?domains=${domain%.duckdns.org}&token=$duckdns_token&ip=
	EOF
	sudo systemctl daemon-reload
fi

# Timer to run the above service every 5 minutes
if [ ! -f /etc/systemd/system/dynamic-dns.timer ]; then
	sudo tee /etc/systemd/system/dynamic-dns.timer <<- 'EOF'
	[Unit]
	Description=Update dynamic DNS entry periodically
	[Timer]
	OnCalendar=*-*-* *:00,05,10,15,20,25,30,35,40,45,50,55:00
	Unit=dynamic-dns.service
	Persistent=true
	[Install]
	WantedBy=timers.target
	EOF
	sudo systemctl daemon-reload
	sudo systemctl enable --now dynamic-dns.timer
fi

# Create Home Assistant restarter service
if [ ! -f /etc/systemd/system/restart-home-assistant.service ]; then
	sudo tee /etc/systemd/system/restart-home-assistant.service <<- 'EOF'
	[Unit]
	Description=Restart Home Assistant containers
	After=multi-user.target
	[Service]
	WorkingDirectory=/srv/home_assistant
	ExecStart=docker compose restart
	EOF
	sudo systemctl daemon-reload
fi

# Timer to run the above service at 03:45 every morning
if [ ! -f /etc/systemd/system/restart-home-assistant.timer ]; then
	sudo tee /etc/systemd/system/restart-home-assistant.timer <<- 'EOF'
	[Unit]
	Description=Restart Home Assistant containers at 03:45
	[Timer]
	OnCalendar=*-*-* 03:45
	Unit=restart-home-assistant.service
	Persistent=true
	[Install]
	WantedBy=timers.target
	EOF
	sudo systemctl daemon-reload
	sudo systemctl enable --now restart-home-assistant.timer
fi

# Modify Docker and WireGuard services to restart whenever iptables service is
# restarted, as these add their own rules
for service in 'docker' 'wg-quick@'; do
	if [ ! -f /etc/systemd/system/"$service".service.d/override.conf ]; then
		sudo mkdir /etc/systemd/system/"$service".service.d/ 2> /dev/null
		sudo tee /etc/systemd/system/"$service".service.d/override.conf <<- 'EOF'
		[Unit]
		PartOf=iptables.service
		EOF
		sudo systemctl daemon-reload
	fi
done

# Add basic configuration
if [ ! -f /etc/iptables/rules.v4 ]; then
	sudo tee /etc/iptables/rules.v4 <<- EOF
	*filter
	--append INPUT --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT
	--append INPUT --in-interface $lan_interface --jump ACCEPT
	--append INPUT --in-interface lo --jump ACCEPT
	--append INPUT --in-interface $wan_interface --protocol icmp --icmp-type echo-request --match limit --limit 1/second --jump ACCEPT
	--append INPUT --in-interface $wan_interface --protocol icmp --icmp-type fragmentation-needed --jump ACCEPT
	--append INPUT --in-interface $wan_interface --protocol icmp --icmp-type time-exceeded --jump ACCEPT
	--append INPUT --in-interface $wan_interface --protocol tcp --dport 80 --match conntrack --ctstate NEW --jump ACCEPT --match comment --comment letsencrypt
	--append INPUT --in-interface $wan_interface --protocol tcp --dport $ha_port --match conntrack --ctstate NEW --jump ACCEPT --match comment --comment ha
	--append INPUT --jump REJECT

	--append FORWARD --match conntrack --ctstate ESTABLISHED,RELATED,DNAT --jump ACCEPT
	--append FORWARD --in-interface $lan_interface --jump ACCEPT
	--append FORWARD --jump REJECT
	COMMIT

	*nat
	--append POSTROUTING --out-interface $wan_interface --jump MASQUERADE
	EOF
	for subnet in $subnets; do
		echo "--append POSTROUTING --source $subnet --dest $subnet --jump MASQUERADE --match comment --comment \"Hairpin NAT\"" | sudo tee -a /etc/iptables/rules.v4
	done
	echo 'COMMIT' | sudo tee -a /etc/iptables/rules.v4
	sudo systemctl restart iptables.service
fi

sudo systemctl enable --now iptables.service

# Configure WireGuard (remote access)
if ! sudo ls /etc/wireguard/wg0.conf > /dev/null 2>&1; then
	sudo tee /etc/wireguard/wg0.conf <<- EOF
	[Interface]
	PrivateKey = $(wg genkey)
	ListenPort = $wg0_port
	Address = $wg0_address/32

	PostUp = iptables --insert INPUT 3 --in-interface %i --jump ACCEPT --match comment --comment 'WireGuard %i'
	PostUp = iptables --insert INPUT 4 --protocol udp --dport $wg0_port --match conntrack --ctstate NEW --jump ACCEPT --match comment --comment 'WireGuard %i'
	PostUp = iptables --insert FORWARD 3 --in-interface %i --jump ACCEPT --match comment --comment 'WireGuard %i'

	PostDown = iptables --delete INPUT --in-interface %i --jump ACCEPT --match comment --comment 'WireGuard %i'
	PostDown = iptables --delete INPUT --protocol udp --dport $wg0_port --match conntrack --ctstate NEW --jump ACCEPT --match comment --comment 'WireGuard %i'
	PostDown = iptables --delete FORWARD --in-interface %i --jump ACCEPT --match comment --comment 'WireGuard %i'
	EOF
	sudo systemctl enable --now wg-quick@wg0.service
fi

# Add iproute2 table for outward tunnel
echo "200 $wg1_peer_shortname" | sudo tee /etc/iproute2/rt_tables.d/"$wg1_peer_shortname".conf

# Configure WireGuard (outward tunnel)
if ! sudo ls /etc/wireguard/wg1.conf > /dev/null 2>&1; then
	sudo tee /etc/wireguard/wg1.conf <<- EOF
	[Interface]
	PrivateKey = $(wg genkey)
	Address = $wg1_address/32
	Table = off

	PostUp = iptables --table nat --insert POSTROUTING 2 --source ${lan_address%.*}.0/24 --out-interface wg1 --jump MASQUERADE --match comment --comment '$wg1_peer_shortname'
	PostUp = ip route add default dev wg1 table $wg1_peer_shortname
	EOF
	for ip in {51..100}; do
		echo "PostUp = ip rule add from ${lan_address%.*}.$ip table $wg1_peer_shortname" | sudo tee -a /etc/wireguard/wg1.conf
	done
	sudo tee -a /etc/wireguard/wg1.conf <<- EOF

	PostDown = iptables --table nat --delete POSTROUTING --source ${lan_address%.*}.0/24 --out-interface wg1 --jump MASQUERADE --match comment --comment '$wg1_peer_shortname'
	PostDown = ip route del default dev wg1 table $wg1_peer_shortname
	EOF
	for ip in {51..100}; do
		echo "PostDown = ip rule del from ${lan_address%.*}.$ip table $wg1_peer_shortname" | sudo tee -a /etc/wireguard/wg1.conf
	done
	sudo tee -a /etc/wireguard/wg1.conf <<- EOF

	#[Peer]
	#PublicKey =
	#AllowedIPs = 0.0.0.0/0
	#Endpoint = $wg1_peer
	EOF
	sudo systemctl enable --now wg-quick@wg1.service
fi

# Create Unifi Controller Docker container directories
sudo mkdir -p /srv/unifi/{data,log}/ 2> /dev/null

# Add script to copy certificates for Docker containers
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy/ > /dev/null 2>&1
if [ ! -f /etc/letsencrypt/renewal-hooks/deploy/copy-certs.sh ]; then
	sudo tee /etc/letsencrypt/renewal-hooks/deploy/copy-certs.sh <<- EOF
	#!/bin/bash

	domain='$domain'

	if [ "\$RENEWED_LINEAGE" = /etc/letsencrypt/live/"\$domain" ]; then
	  # For containers that use the default Let's Encrypt naming scheme
	  # Docker volumes don't allow symlinks to be resolved
	  sudo mkdir -p /srv/ssl/ > /dev/null 2>&1
	  sudo cp -r --dereference /etc/letsencrypt/live/"\$domain"/* /srv/ssl/

	  # Restart all Docker containers
	  sudo docker restart \$(sudo docker ps | awk '!/CONTAINER ID/ { print \$1 }')
	fi
	EOF
	sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/copy-certs.sh
fi

# Add current user to docker group
sudo usermod -aG docker "$USER"

# Clone dotfiles
git clone --bare git@github.com:jmcvaughn/dotfiles.git "$HOME"/.dotfiles/
git --git-dir="$HOME"/.dotfiles/ --work-tree="$HOME"/ config core.sparseCheckout true
printf '/*\n!/README.md\n' > "$HOME"/.dotfiles/info/sparse-checkout
git --git-dir="$HOME"/.dotfiles/ --work-tree="$HOME"/ checkout home-router
git --git-dir="$HOME"/.dotfiles/ --work-tree="$HOME"/ submodule update --init --recursive --jobs 4

# Set shell to Zsh
if [ "$(awk -F ':' "/$USER/ { print \$7 }" /etc/passwd)" != '/bin/zsh' ]; then
	chsh -s /bin/zsh
fi
