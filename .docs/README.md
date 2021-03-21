# home-router branch

## Installation

At the *SSH Setup* screen, remember to select *Install OpenSSH server* and *Allow password authentication over SSH*.
This is required to initially access the system remotely, assuming that the installation is offline.

## System setup

- Prior to running `setup.sh`, [download and install the `ppp` package](https://packages.ubuntu.com/focal-updates/amd64/ppp/download).
This is required to connect the system to the Internet.
All of its dependencies will already be installed.

- Install an SSH key pair or create a new key pair and add it to GitHub:

```shell
ssh-keygen -b 4096 -t rsa -N '' -f ~/.ssh/id_rsa
```

- Configure the variables at the top of `setup.sh`, then copy it to the server.

- Run `setup.sh`.
This will set the system up to the point of, but not including, configuring dnsmasq to provide DHCP and DNS to clients.
You will be prompted to save current iptables rules.
As there won't be any, select *No* for both IPv4 and IPv6.

- Run `nvim.sh`

- Setup Canonical Livepatch if running an Ubuntu LTS release

## Post-install setup

There are three main tasks to make turn this into a fully-fledged home gateway/router:

- Add any DHCP/DNS configuration in dnsmasq

- Add any custom rules in iptables

- Add any static routes in netplan

### dnsmasq

By default, `dnsmasq` reads configuration files in /etc/dnsmasq.d/, leaving it to the user to choose how to lay out these files.
See the following example:

```shell
$ cat /etc/dnsmasq.d/192.168.1.0-24
listen-address = 192.168.1.1

server = /test2.lan/192.168.2.1

dhcp-range = set:main, 192.168.1.101, 192.168.1.120
dhcp-option = tag:main, option:router, 192.168.1.1
dhcp-option = tag:main, option:dns-server, 192.168.1.1
dhcp-option = tag:main, option:domain-search, example.lan
dhcp-option = tag:main, option:domain-name, example.lan

host-record = router.example.lan, 192.168.1.1

dhcp-host = 00:11:22:aa:bb:cc, 192.168.1.2, acomputer
```

### iptables

#### Port forwarding

This can be done by adding a rule to the `PREROUTING` chain of the `nat` table:

```shell
*nat
--append PREROUTING --protocol tcp --dport 65536 --jump DNAT --to-destination 192.168.1.2:22 --match comment --comment "machine1/ssh"
COMMIT
```

There is a pre-existing `FORWARD` chain rule in the `filter` table that handles the DNAT conntrack state; no additional rules are required.

#### Allowing direct access to the router

This can be done by adding a rule to the `INPUT` chain of the `filter` table:

```shell
*filter
--append INPUT --in-interface pppoe0 --protocol tcp --dport 22 --match conntrack --ctstate NEW --jump ACCEPT
COMMIT
```

However, exposing a registered or dynamic port is recommended instead.
To use the same internal port but expose a different port externally, add the following rules:

```shell
*nat
--append PREROUTING --protocol tcp --dport 65535 --jump REDIRECT --to-port 22  # Port redirection example (i.e. for this machine)
COMMIT
```
