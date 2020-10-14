# home-server branch

The documentation and scripts in this branch were copied and modified from my old [server_setup](https://github.com/jmcvaughn/server_setup) repository. For these components, this branch can be considered a continuation of that repository.

## Installation

For my configuration, most working data is stored in separate ZFS file systems. As a result, the boot disk partitioning scheme doesn't matter too much; an ESP partition and a root partition is sufficient. If a disaster occurs, the installation can be rebuilt with minimal effort.

As of Subiquity 20.04.2, the creation of multiple ESPs is supported. However, this functionality is only supported if booting newer installers; updating doesn't work. Therefore, you must use the Ubuntu Server 20.04.1 LTS live disk image or newer. To set up multiple ESPs, at the *Guided storage configuration* page, select *Custom storage layout*. Under the *Storage configuration* page, select *Use As Boot Device* and *Add As Another Boot Device* for your primary and backup devices respectively.

At the *SSH Setup* screen, remember to select *Install OpenSSH server* and *Allow password authentication over SSH* (this is required by MAAS to reach libvirt).

There is no requirement to install any snaps at the *Featured Server Snaps* screen; those required are installed by the scripts in this repository.

## System setup

Prior to running `setup.sh`:

- Install the ZFS utilities:

```shell
sudo apt-get update && sudo apt-get -y install zfsutils-linux
```

- Manually import and mount/create ZFS pools and datasets as required:

```shell
sudo -i
rm -r ~jamesvaughn/{,.}*
zpool import -af
```

After running `setup.sh`, enable [Canonical Livepatch](https://ubuntu.com/livepatch).

## MAAS and KVM

All virtualisation requirements are met by MAAS and KVM. Before setting up MAAS, set a password for the `maas` user, which will be used by MAAS to connect to libvirt:

```shell
sudo passwd maas
```

`setup.sh` installs the `maas` and `maas-test-db` snap packages. To set up MAAS:

- Initialise MAAS:

```shell
sudo maas init region+rack --database-uri maas-test-db:///
```

- Create an admin user:

```shell
sudo maas createadmin
```

- Sign in to the MAAS web UI and change the following settings:

```yaml
Settings:
  Configuration:
    General:
      Enable analytics to shape improvements to user experience: False
  Network:
    Network discovery:
      Network discovery: False
```

- Configure the server as a KVM host by following the (Adding a VM host)[https://maas.io/docs/add-a-vm-host] page of the MAAS documentation.

Then proceed with any required MAAS configuration as normal.
