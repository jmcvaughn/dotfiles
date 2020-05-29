# generic-ubuntu-server branch
For virtual or physical Ubuntu 16.04 LTS, 18.04 LTS, or 20.04 LTS server installations.

## Usage
Follow [the main repository README](../README.md) for cloning instructions for normal usage, though note that some packages may need to be installed.

.scripts/setup.sh has been written to be idempotent. It can be run as part of the provisioning process or on a freshly provisioned system. For Vagrant, to use .scripts/setup.sh during the provisioning process, create a Vagrantfile as follows:
```
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.provision "shell", path: "https://raw.githubusercontent.com/jmcvaughn/dotfiles/generic-ubuntu-server/.scripts/setup.sh"
end

# vim: set filetype=ruby:
```

For clouds (e.g. OpenStack), download and pass the script as a user-data script.
