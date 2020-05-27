# vagrant-ubuntu-desktop branch
This branch has only been tested with the official Ubuntu Bionic (18.04) Vagrant images. Xenial is not supported, and Focal has not yet been tested due to performance issues with VirtualBox.

## Usage
.scripts/setup.sh has been written to be idempotent. It can be run as part of the provisioning process with Vagrant or on a freshly provisioned system.

Follow [the main repository README](../README.md) for cloning instructions for normal usage, though note that some packages may need to be installed.

To use .scripts/setup.sh during the provisioning process, create a Vagrantfile as follows:
```
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = true

    vb.cpus = 1
    vb.memory = 3072
    vb.customize ["modifyvm", :id, "--vram", "16"]
  end

  config.vm.provision "shell", path: "https://raw.githubusercontent.com/jmcvaughn/dotfiles/vagrant-ubuntu-desktop/.scripts/setup.sh"
end

# vim: set filetype=ruby:
```
