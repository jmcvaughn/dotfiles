#!/bin/bash

domain=''
duckdns_token=''
lan_interface=eno1
subnets=''
wan_interface=enp2s0
wg0_port=''
wg0_address=''  # Without subnet mask or CIDR
znc_port=''

packages=(
	apparmor-utils
	apt-file
	aria2
	default-jre-headless
	devscripts
	dnscrypt-proxy
	dnsmasq
	gh
	ipmitool
	iptables-persistent
	jq
	ksmtuned
	language-pack-en
	net-tools
	nfs-common
	smartmontools
	speedtest-cli
	tree
	wireguard
	zip
	znc
	zsh
)

sudo systemctl disable --now {systemd-resolved,ufw}.service

# Enable forwarding
if [ ! -f /etc/sysctl.d/99-z-forwarding.conf ]; then
	echo 'net.ipv4.conf.all.forwarding = 1' | sudo tee /etc/sysctl.d/99-z-forwarding.conf
	sudo sysctl -p /etc/sysctl.d/99-z-forwarding.conf
fi

# Create script to prevent dhclient from modifying /etc/resolv.conf
sudo tee /etc/dhcp/dhclient-enter-hooks.d/resolvconf_null << 'EOF'
#!/bin/bash

make_resolv_conf() {
	exit 0
}
EOF
sudo chmod +x /etc/dhcp/dhclient-enter-hooks.d/resolvconf_null

# Configure dhclient for WAN interface
[ ! -f /etc/dhcp/dhclient."$wan_interface".conf ] && sudo tee /etc/dhcp/dhclient."$wan_interface".conf << 'EOF'
option rfc3442-classless-static-routes code 121 = array of unsigned integer 8;

request broadcast-address,
	interface-mtu,
	routers,
	rfc3442-classless-static-routes,
	subnet-mask;

# anything@skydsl|anything
send dhcp-client-identifier 61:6e:79:74:68:69:6e:67:40:73:6b:79:64:73:6c:7c:61:6e:79:74:68:69:6e:67;
EOF

# Create systemd template service for dhclient and start dhclient service for
# WAN interface
if [ ! -f /etc/systemd/system/dhclient@.service ]; then
	sudo tee /etc/systemd/system/dhclient@.service <<- 'EOF'
	[Unit]
	Description=Run dhclient for interface %I
	Wants=network.target
	BindsTo=sys-subsystem-net-devices-%i.device
	Before=network.target
	After=sys-subsystem-net-devices-%i.device

	[Service]
	PIDFile=dhclient.%I.pid
	ExecStart=/usr/sbin/dhclient -4 -d -cf /etc/dhcp/dhclient.%I.conf -lf /var/lib/dhcp/dhclient.%I.leases -pf /run/dhclient.%I.pid %I
	Restart=always

	[Install]
	WantedBy=multi-user.target
	EOF
	sudo systemctl daemon-reload
	sudo systemctl enable dhclient@"$wan_interface".service
	sudo systemctl restart dhclient@"$wan_interface".service
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

sudo apt-get update

# Add repositories
## GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Install packages
sudo apt-get update
sudo apt-get -y install ${packages[@]}
for i in canonical-livepatch docker; do
	sudo snap install "$i"
done
for i in certbot nvim; do
	sudo snap install "$i" --classic
done
sudo snap install --channel 18/stable --classic node

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
if ! grep -q 'nameserver 127.0.0.1' /etc/resolv.conf; then
	sudo tee /etc/resolv.conf <<- EOF
	nameserver 127.0.0.1
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

# Modify WireGuard service to restart whenever iptables service is restarted,
# as this adds its own rules
for service in 'wg-quick@'; do
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
	--append INPUT --in-interface $wan_interface --protocol tcp --dport $znc_port --match conntrack --ctstate NEW --jump ACCEPT --match comment --comment znc
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

# Configure WireGuard
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

# Create Unifi Controller Docker container directories
mkdir -p "$HOME"/unifi/{data,log}/ 2> /dev/null

# Add ZNC TLS certificate update script
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy/ > /dev/null 2>&1
if [ ! -f /etc/letsencrypt/renewal-hooks/deploy/znc.sh ]; then
	sudo tee /etc/letsencrypt/renewal-hooks/deploy/znc.sh <<- EOF
	#!/bin/bash

	domain='$domain'

	if [ "\$RENEWED_LINEAGE" = /etc/letsencrypt/live/"\$domain" ]; then
		cat /etc/letsencrypt/live/"\$domain"/{privkey,fullchain}.pem > /var/lib/znc/znc.pem
	fi
	EOF
fi
sudo chmod 0755 /etc/letsencrypt/renewal-hooks/deploy/znc.sh

# Enable ZNC
## ZNC home directory is set to /var/lib/znc/, which means that
## `znc --makeconfig` writes to /var/lib/znc/.znc/. However, znc.service uses
## /var/lib/znc/, so symlinking the former to the latter is convenient.
sudo ln -sf /var/lib/znc/ /var/lib/znc/.znc
sudo chmod 0700 /var/lib/znc/
sudo systemctl enable znc.service

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
