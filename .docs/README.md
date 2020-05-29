# generic-ubuntu-desktop branch
For virtual or physical Ubuntu desktop installations, presuming a server installation as a base.

For Vagrant, this branch has only been tested with the official Ubuntu Bionic (18.04) images. Xenial is not supported, and Focal has not yet been tested due to performance issues with VirtualBox.

## Usage
Follow [the main repository README](../README.md) for cloning instructions for normal usage, though note that some packages may need to be installed.

.scripts/setup.sh has been written to be idempotent. It can be run as part of the provisioning process or on a freshly provisioned system. For Vagrant, to use .scripts/setup.sh during the provisioning process, create a Vagrantfile as follows:
```
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = true

    vb.cpus = 1
    vb.memory = 3072
    vb.customize ["modifyvm", :id, "--vram", "16"]
  end

  config.vm.provision "shell", path: "https://raw.githubusercontent.com/jmcvaughn/dotfiles/generic-ubuntu-desktop/.scripts/setup.sh"
end

# vim: set filetype=ruby:
```

For clouds (e.g. OpenStack), download and pass the script as a user-data script.

**WARNING: Auto-login is enabled by default.** To disable it, download the script, comment or remove the 'Configure auto-login' section, and pass it as a local script.
