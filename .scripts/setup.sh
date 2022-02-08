#!/bin/bash

wan_interface=enp2s0
lan_interface=eno1
pppoe_jumbo=1
subnets=''
search=''
pppoe_user=''
pppoe_password=''
wg0_port=''
wg0_address=''  # Without subnet mask or CIDR
domain=''
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
	neovim
	nfs-common
	nodejs
	ppp
	smartmontools
	speedtest-cli
	tree
	wireguard
	yarn
	zip
	znc
	zsh
)

sudo systemctl disable --now {systemd-resolved,ufw}.service

# Enable discard for the root ('/') file system, remount
rootfs_uuid=$(lsblk -lno mountpoint,uuid | awk '$1 == "/" { print $2 }')
if ! grep -E "^[^#].*$rootfs_uuid.+discard" /etc/fstab; then
	sudo sed -i "/$rootfs_uuid/ s/defaults/defaults,discard/" /etc/fstab
	sudo mount -o remount /
fi

# Ensure interface is up and with correct MTU
if [ ! -f /etc/netplan/10-"$wan_interface".yaml ]; then
	if [ "${pppoe_jumbo:-0}" = 1 ]; then
		sudo tee /etc/netplan/10-"$wan_interface".yaml <<- EOF
		network:
		  ethernets:
		    $wan_interface:
		      mtu: 1508
		EOF
	else
		sudo tee /etc/netplan/10-"$wan_interface".yaml <<- EOF
		network:
		  ethernets:
		    $wan_interface: {}
		EOF
	fi
	sudo netplan apply
fi

# Generate ppp configuration
if [ ! -f /etc/ppp/peers/pppoe0 ]; then
	sudo tee /etc/ppp/peers/pppoe0 <<- EOF
	# See pppd(8)

	plugin rp-pppoe.so  # Must be immediately before interface

	## Frequently Used Options
	$wan_interface
	user "$pppoe_user"
	password "$pppoe_password"
	defaultroute

	## Options
	ifname pppoe0
	ipparam pppoe0
	maxfail 0
	noauth
	noipdefault
	noproxyarp
	persist

	## https://tools.ietf.org/html/rfc2516#section-7
	default-asyncmap
	noaccomp
	EOF

	[ "${pppoe_jumbo:-0}" = 0 ] && sudo tee -a /etc/ppp/peers/pppoe0 <<- 'EOF'

	mru 1492
	mtu 1492
	EOF
fi

# Add ppp systemd service
if [ ! -f /etc/systemd/system/ppp@.service ]; then
	sudo tee /etc/systemd/system/ppp@.service <<- 'EOF'
	[Unit]
	Description=PPP provider %I
	Before=network.target

	[Service]
	ExecStart=/usr/sbin/pppd call %I nodetach nolog

	[Install]
	WantedBy=multi-user.target
	EOF
	sudo systemctl daemon-reload
fi

# Enable ppp service for pppoe0
sudo systemctl enable --now ppp@pppoe0.service

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
## Neovim
sudo add-apt-repository -y ppa:neovim-ppa/unstable
## Node.js and Yarn
curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
## GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Install packages
sudo apt-get update
sudo apt-get -y install ${packages[@]}
# sudo snap install canonical-livepatch  # Uncomment if running LTS release
for i in batcat certbot; do
	sudo snap install "$i" --classic
done

# Set locale
sudo update-locale LANG=en_GB.UTF-8

# Configure dnsmasq to use dnscrypt-proxy for resolution
if [ ! -f /etc/dnsmasq.d/jmcvaughn-dotfiles ]; then
	sudo tee /etc/dnsmasq.d/jmcvaughn-dotfiles <<- 'EOF'
	# Redirect everything to dnscrypt-proxy
	listen-address = 127.0.0.1  # Required as dnscrypt-proxy also listens on lo
	no-resolv
	server = 127.0.2.1
	cache-size = 0  # dnscrypt-proxy caches
	dnssec
	conf-file = /usr/share/dnsmasq-base/trust-anchors.conf
	EOF
	sudo systemctl restart dnsmasq.service
fi

# Move to local nameserver now that dnsmasq is running
if ! grep -q 'nameserver 127.0.0.1' /etc/resolv.conf; then
	sudo tee /etc/resolv.conf <<- EOF
	nameserver 127.0.0.1
	search $search
	EOF
fi

# Disable password authentication for SSH
if [ ! -f /etc/ssh/sshd_config.d/password_auth.conf ]; then
	ssh-import-id gh:jmcvaughn
	sudo tee /etc/ssh/sshd_config.d/password_auth.conf <<- 'EOF' 
	PasswordAuthentication no
	EOF
	sudo systemctl restart sshd.service
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
		systemd_reload=1
	fi
done
[ "${systemd_reload:-0}" = 1 ] && sudo systemctl daemon-reload

# Add basic configuration
if [ ! -f /etc/iptables/rules.v4 ]; then
	for subnet in $subnets; do
		hairpin_nat_rules=${hairpin_nat_rules}$(printf -- "--append POSTROUTING --source $subnet --dest $subnet --jump MASQUERADE --match comment --comment \"Hairpin NAT\"\n")
	done
	sudo tee /etc/iptables/rules.v4 <<- EOF
	*filter
	--append INPUT --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT
	--append INPUT --in-interface $lan_interface --jump ACCEPT
	--append INPUT --in-interface lo --jump ACCEPT
	--append INPUT --in-interface pppoe0 --protocol icmp --icmp-type echo-request --match limit --limit 1/second --jump ACCEPT
	--append INPUT --in-interface pppoe0 --protocol icmp --icmp-type fragmentation-needed --jump ACCEPT
	--append INPUT --in-interface pppoe0 --protocol icmp --icmp-type time-exceeded --jump ACCEPT
	--append INPUT --in-interface pppoe0 --protocol tcp --dport 80 --match conntrack --ctstate NEW --jump ACCEPT --match comment --comment letsencrypt
	--append INPUT --in-interface pppoe0 --protocol tcp --dport $znc_port --match conntrack --ctstate NEW --jump ACCEPT --match comment --comment znc
	--append INPUT --jump REJECT

	--append FORWARD --match conntrack --ctstate ESTABLISHED,RELATED,DNAT --jump ACCEPT
	--append FORWARD --in-interface $lan_interface --jump ACCEPT
	--append FORWARD --jump REJECT
	COMMIT

	*nat
	--append POSTROUTING --out-interface pppoe0 --jump MASQUERADE
	$hairpin_nat_rules
	COMMIT
	EOF

	[ "${pppoe_jumbo:-0}" = 0 ] && sudo tee -a /etc/iptables/rules.v4 <<- 'EOF'

	*mangle
	--append FORWARD --protocol tcp --tcp-flags SYN,RST SYN --jump TCPMSS --clamp-mss-to-pmtu
	COMMIT
	EOF
	sudo systemctl restart iptables.service
fi

sudo systemctl enable --now iptables.service

# Configure WireGuard
if ! sudo ls /etc/wireguard/wg0.conf > /dev/null 2>&1; then
	cat <<- EOF | sudo tee /etc/wireguard/wg0.conf
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

# Add ZNC TLS certificate update script
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy/ > /dev/null 2>&1
if [ ! -f /etc/letsencrypt/renewal-hooks/deploy/znc.sh ]; then
	cat <<- EOF | sudo tee /etc/letsencrypt/renewal-hooks/deploy/znc.sh
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
