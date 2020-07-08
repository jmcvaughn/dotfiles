# generic-ubuntu-desktop branch
For virtual or physical Ubuntu desktop installations, presuming a server installation as a base.

For Vagrant, this branch has only been tested with the official Ubuntu Bionic (18.04) images. Xenial is not supported, and Focal has not yet been tested due to performance issues with VirtualBox.

## Usage
Follow [the main repository README](../README.md) for cloning instructions for normal usage, though note that some packages may need to be installed.

[.scripts/setup.sh](../.scripts/setup.sh) has been written to be idempotent. It can be run as part of the provisioning process or on a freshly provisioned system. For Vagrant, to use [.scripts/setup.sh](../.scripts/setup.sh) during the provisioning process, refer to the included [Vagrantfile](Vagrantfile) as a starting point.

For clouds (e.g. OpenStack), download and pass [.scripts/setup.sh](../.scripts/setup.sh) as a user-data script.

**WARNING: Auto-login is enabled by default.** To disable it, download the script, comment or remove the 'Configure auto-login' section, and pass it as a local script.
