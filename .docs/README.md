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

- Run `helptags ALL` in `nvim` to generate helptags

- Setup Canonical Livepatch if running an Ubuntu LTS release

## Post-install setup

There are three main tasks to make turn this into a fully-fledged home gateway/router/VPN server:

- Add any DHCP/DNS configuration in dnsmasq

- Add any custom rules in iptables

- Add any static routes in netplan

- Add any peers to WireGuard's wg0 configuration.

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

However, exposing a unregistered or dynamic port is recommended instead.
To use the same internal port but expose a different port externally, add the following rules:

```shell
*nat
--append PREROUTING --protocol tcp --dport 65535 --jump REDIRECT --to-port 22  # Port redirection example (i.e. for this machine)
COMMIT
```

### WireGuard

Note that more complicated configurations are possible, but the configuration here is suitable for my requirements.

`setup.sh` creates a base configuration for WireGuard at /etc/wireguard/wg0.conf and enables and starts `wg-quick@wg0.service`.

WireGuard doesn't have the notion of servers and clients; it instead only considers *peers*.
However, for the sake of this configuration, we will incorrectly continue to refer to them as servers (referring to this router) and clients (referring to any device that connects to the server).
The main difference with a WireGuard server is that it will have a network port statically configured.

In the example below, the following presumptions are being made:

- Server keys:
  - Private: `oERMfmf7pLKGyu2QPHGxplHDfvjmr9i708FBRntZ+Wc=`
  - Public: `iIZGD3FKP6eodx2eECzHVU3Xxl6+v+yYV2fCy2DRQDA=`
- Client keys:
  - Private: `yMTnHXZzk93xTzBfaTnQwqRDt4xKl0dHsK8YhUHbQm8=`
  - Public: `xxqNbZzNFIwARPrmihyCoc/acexfwyVnI9/sAUExAi4=`
- WireGuard subnet: 192.168.10.0/24 (this would be configured at the top of `setup.sh`)
- WireGuard port: 56789 (this would be configured at the top of `setup.sh`)
- WireGuard client IP: 192.168.10.10/32
- Home subnet: 192.168.1.0/24
- Home DNS: 192.168.1.1/24
- Home domain: example.com
- Home public IP address: 93.184.216.34 (the IP address of example.com at the time of writing)

To add a client:

- Derive the server's public key from its private key (which can be found in /etc/wireguard/wg0.conf):

  ```shell
  $ echo oERMfmf7pLKGyu2QPHGxplHDfvjmr9i708FBRntZ+Wc= | wg pubkey
  iIZGD3FKP6eodx2eECzHVU3Xxl6+v+yYV2fCy2DRQDA=
  ```

- Generate a keypair for the client by following the wg(8) man page's guidance, ideally on the client if the `wg` utility is available:

  > A private key and a corresponding public key may be generated at once by calling:
  >
  >   ```shell
  >   $ umask 077
  >   $ wg genkey | tee private.key | wg pubkey > public.key
  >   ```

  Alternatively, a GUI client can generate these keys for you.

- On the server, add a `[Peer]` entry as follows to /etc/wireguard/wg0.conf:

  ```text
  [Peer]
  PublicKey = xxqNbZzNFIwARPrmihyCoc/acexfwyVnI9/sAUExAi4=
  AllowedIPs = 192.168.10.10/32
  ```

  Where `PublicKey` is the client's public key that was just generated, and `AllowedIPs` is the IP address for the WireGuard interface on the client.

- Restart the service to apply the configuration:

  ```shell
  sudo systemctl systemctl restart wg-quick@wg0.service
  ```

- On the client, add a new tunnel configuration as follows:

  ```text
  [Interface]
  PrivateKey = yMTnHXZzk93xTzBfaTnQwqRDt4xKl0dHsK8YhUHbQm8=
  Address = 192.168.10.10/32
  DNS = 192.168.1.1, example.com

  [Peer]
  PublicKey = iIZGD3FKP6eodx2eECzHVU3Xxl6+v+yYV2fCy2DRQDA=
  AllowedIPs = 0.0.0.0/0
  Endpoint = 93.184.216.34:56789
  ```

  This will route all traffic via WireGuard; change `AllowedIPs` to specific subnets to only route those subnets via the tunnel.
  Note that on macOS clients, due to an Apple bug (see point 9 of section D of [this link](https://docs.google.com/document/d/1BnzImOF8CkungFnuRlWhnEpY2OmEHSckat62aZ6LYGY/edit)), search domains won't be set unless `AllowedIPs` is set to `0.0.0.0/0`.

### Let's Encrypt certificate

Run `sudo certbot certonly --standalone`.

### ZNC

Run `sudo -u _znc znc --makeconf` and specify the port configured at the top of `setup.sh`. Do not start select "Yes" when prompted to start ZNC; run `sudo systemctl start znc.service` instead.
