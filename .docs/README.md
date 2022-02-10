# home-server branch

The documentation and scripts in this branch were copied and modified from my old [server_setup](https://github.com/jmcvaughn/server_setup) repository. For these components, this branch can be considered a continuation of that repository.

## Installation

For my configuration, most working data is stored in separate ZFS file systems. As a result, the boot disk partitioning scheme doesn't matter too much; an ESP partition and a root partition is sufficient. If a disaster occurs, the installation can be rebuilt with minimal effort.

As of Subiquity 20.04.2, the creation of multiple ESPs is supported. However, this functionality is only supported if booting newer installers; updating doesn't work. Therefore, you must use the Ubuntu Server 20.04.1 LTS live disk image or newer. To set up multiple ESPs, at the *Guided storage configuration* page, select *Custom storage layout*. Under the *Storage configuration* page, select *Use As Boot Device* and *Add As Another Boot Device* for your primary and backup devices respectively.

At the *SSH Setup* screen, remember to select *Install OpenSSH server*.

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

Remember to set `ashift` to an appropriate value for your disks. If creating a dataset to host VM images, remember to set `recordsize` to match the disk block size to minimise write amplification. For SSD pools, enable `autotrim` with `sudo zpool set autotrim=on <POOL>`. A period manual TRIM or externally-scheduled TRIM (e.g. cron or systemd timer) is recommended as automatic TRIM skips small ranges. `setup.sh` adds a script, systemd service and timer to do this daily for all pools with `autotrim` enabled.

After running `setup.sh`, enable [Canonical Livepatch](https://ubuntu.com/livepatch).

If using an Intel server board, consider installing Intel's One Boot Flash Update (OFU) utility to update firmware from the operating system by downloading it from https://downloadcenter.intel.com and installing the include deb package:

```shell
sudo apt-get update && sudo apt-get -y install /path/to/flashupdt
```

As Intel incorrectly installs this to /usr/local/flashupdt/flashupdt (i.e. outside of `$PATH`), a symlink in /usr/local/sbin/ is created by `setup.sh`.

Finally, run `helptags ALL` in `nvim` to generate helptags.

## MAAS and KVM

All virtualisation requirements are met by MAAS and KVM. However, as MAAS KVM pods do not allow the oversubscription of storage, virtual machines are instead managed using the [`addvm`](../bin/addvm) and [`rmvm`](../bin/rmvm) scripts for virtual machine creation and deletion respectively, the [`release`](../bin/release) script to power off virtual machines in the "Ready" state and the [`deploy`](../bin/deploy) script to power on machines that are in a "Deploying" state. [KSM](https://www.kernel.org/doc/html/latest/admin-guide/mm/ksm.html) and [ksmtuned](https://github.com/ksmtuned/ksmtuned) is used to de-duplicate virtual machine pages in memory.

`setup.sh` installs the `maas` and `maas-test-db` snap packages. To set up MAAS:

- Initialise MAAS:

```shell
sudo maas init region+rack --database-uri maas-test-db:///
```

- Create an admin user using your username and set up the MAAS CLI (as required by several scripts in ~/bin/):

```shell
sudo maas createadmin --username "$USERNAME" --email <EMAIL>
sudo maas apikey --username "$USERNAME" | maas login "$(hostname -s)" MAAS_URL -
```

- Sign in to the MAAS web UI and change the following settings:

```yaml
Settings:
  Configuration:
    General:
      Enable analytics to shape improvements to user experience: False
    Kernel parameters: console=ttyS0
  Network:
    Network discovery:
      Network discovery: False
```

- Create the "maas0" space and add the 10.188.0.0/16 fabric, and configure/enable DHCP on it

- Set a reserved range for VIPs as per [`VIP_ADDR_START` in my stsstack-bundles fork](https://git.launchpad.net/~jmcvaughn/stsstack-bundles/tree/common/helpers?h=jvaughnserver#n11)

- Set a reserved range for OpenStack floating IPs as per [`FIP_RANGE` in my stsstack-bundles fork](https://git.launchpad.net/~jmcvaughn/stsstack-bundles/tree/openstack/profiles/jvaughnserver?h=jvaughnserver#n6)

Then proceed with any required MAAS configuration as normal, e.g. adding virtual machines using the `jjvm` and `addvm` scripts, setting up Juju.
