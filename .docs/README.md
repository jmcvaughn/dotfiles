# generic-ubuntu-server branch
For virtual or physical Ubuntu 16.04 LTS, 18.04 LTS, or 20.04 LTS server installations.

## Usage
Follow [the main repository README](../README.md) for cloning instructions for normal usage, though note that some packages may need to be installed.

[.scripts/setup.sh](../.scripts/setup.sh) has been written to be idempotent. It can be run as part of the provisioning process or on a freshly provisioned system. For Vagrant, to use [.scripts/setup.sh](../.scripts/setup.sh) during the provisioning process, refer to the included [Vagrantfile](Vagrantfile) as a starting point.

For clouds (e.g. OpenStack), download and pass [.scripts/setup.sh](../.scripts/setup.sh) as a user-data script.
