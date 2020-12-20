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

- Add any DHCP/DNS configuration for dnsmasq, port forwarding rules for iptables, any static routes for netplan

- Setup Canonical Livepatch
