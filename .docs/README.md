# mac branch

This branch was copied and modified from my old [mac\_setup](https://github.com/jmcvaughn/mac_setup) repository. In terms of the system configuration itself, this branch can be considered a continuation of that repository.

## macOS intial setup

It is presumed during the setup process that where possible, "Set Up Later" or "Not Now" was selected, aside from for Location Settings (as this is required to enable NTP). Otherwise, if "Customise Settings" is available, it is presumed that defaults (i.e. "Continue") were used. It is also presumed that "Enable Ask Siri" is untouched (i.e. enabled).

## Usage

Note that some of the manual tasks in particular might need to be performed out of order, and that some tasks *can* be performed out of order. However, as a general gist:

1) Go to System Settings > Privacy & Security > Full Disk Access and enable this for Terminal. During the installation process and in general operation you may be prompted to grant Terminal access to Contacts and to control System Events; allow these.
1) Install SSH key pair or set up new key pair on GitHub (`ssh-keygen -b 4096 -t rsa -N '' -f ~/.ssh/id_rsa`)
1) Install Xcode Command Line Tools by running `xcode-select --install`
1) Follow the cloning instructions in the main repository [README](../README.md)
1) Sign in to the Mac App Store
1) Run `../.scripts/packages.sh`. You'll be prompted to allow various system extensions; allow them aside from "Oracle American Inc." (VirtualBox).
1) Run `../.scripts/system_settings.sh`
1) Reboot
1) Launch Karabiner to set up the virtual keyboard device
1) Perform tasks specified in `manual_tasks.yaml`
1) Run `../.scripts/app_settings.sh`
1) Install Python packages: `pip3 install -r ../.scripts/requirements.txt`
1) Run `../bin/update` to pull all Git repositories and Neovim/Zsh plugins
1) Run `helptags ALL` in nvim to generate helptags
1) Go to System Settings > Privacy & Security > Full Disk Access and remove Terminal.
