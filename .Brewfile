#-------------------------------------------------------------------------------
# Casks
#-------------------------------------------------------------------------------

tap 'homebrew/cask'  # Explicitly tap to keep during `brew bundle cleanup`
cask 'anydesk'
cask 'citrix-workspace'
cask 'coconutbattery'
cask 'displaycal'
cask 'drawio'
cask 'firefox'
cask 'google-chrome'
cask 'iina'
cask 'iterm2'
cask 'karabiner-elements'
cask 'launchbar'
cask 'librecad'
cask 'microsoft-teams'
cask 'netnewswire'
cask 'qobuz'
cask 'raspberry-pi-imager'
cask 'slack'
cask 'soundsource'
cask 'tailscale'
cask 'telegram'
cask 'tunnelblick'
cask 'vagrant'
cask 'vagrant-manager'
cask 'vagrant-vmware-utility'
cask 'virtualbox'  # Required for Vagrant even if unused
cask 'vmware-fusion'
cask 'vmware-horizon-client'
cask 'whatsapp'
cask 'wkhtmltopdf'  # Used by pandoc to create files
cask 'zoom'

# Alternative versions
tap 'homebrew/cask-versions'
cask 'sonos-s1-controller'


#-------------------------------------------------------------------------------
# Homebrew packages
#-------------------------------------------------------------------------------

brew 'ansible'
brew 'ansible-lint'
brew 'aria2'
brew 'asciinema'
brew 'awscli'
brew 'ffmpeg'
brew 'exiftool'
brew 'fd'  # fzf-lua (LazyVim)
brew 'font-sauce-code-pro-nerd-font'
brew 'fzf'  # fzf-lua (LazyVim)
brew 'gh'
brew 'git'
brew 'gnupg'
brew 'imagemagick'
brew 'ipmitool'
brew 'iproute2mac'
brew 'jq'
brew 'luarocks'
brew 'mas'
brew 'neovim'
brew 'node'
brew 'oci-cli'
brew 'p7zip'
brew 'pandoc'
brew 'pdsh'
brew 'pinentry-mac'
brew 'pyenv'
brew 'pylint'
brew 'ripgrep'  # fzf-lua (LazyVim)
brew 'rsync'
brew 'sipcalc'
brew 'speedtest-cli'
brew 'teleport'
brew 'tree'
brew 'watch'
brew 'xz'
brew 'yamllint'
brew 'yarn'

# GNU utilities
brew 'coreutils'
brew 'diffutils'
brew 'findutils'
brew 'gawk'
brew 'gnu-sed'
brew 'gnu-tar'
brew 'grep'
brew 'gzip'
brew 'wget'

# Kubernetes
brew 'helm'
brew 'k9s'
brew 'kubectl'

# Window manager
tap 'homebrew/services'  # Explicitly tap to keep during `brew bundle cleanup`
tap 'koekeishiya/formulae'
brew 'yabai'
brew 'skhd'

# Hashicorp Terraform
tap 'hashicorp/tap'
brew 'hashicorp/tap/terraform'  # Run `terraform -install-autocomplete` afterwards


#-------------------------------------------------------------------------------
# Mac App Store
#-------------------------------------------------------------------------------

mas 'Actions', id: 1586435171  # For developing iOS Shortcuts on Mac
mas 'AdGuard for Safari', id: 1440147259
mas 'Linn', id: 1292218680
mas 'Numbers', id: 409203825
mas 'Pages', id: 409201541
mas 'PiPifier', id: 1160374471
mas 'WireGuard', id: 1451685025
mas 'Unread', id: 1363637349
mas 'Twingate', id: 1501592214

# Microsoft
mas 'Microsoft Excel', id: 462058435
mas 'Microsoft Powerpoint', id: 462062816
mas 'Microsoft Word', id: 462054704
mas 'Okta Verify', id: 490179405
mas 'OneDrive', id: 823766827
mas 'Windows App', id: 1295203466


#-------------------------------------------------------------------------------
# QMK
# https://docs.qmk.fm/#/newbs_getting_started?id=set-up-your-environment
#-------------------------------------------------------------------------------

# All packages are dependencies of the "qmk" package. They are all specified
# here to ensure they're kept during a `brew bundle cleanup`. The same applies
# for packages in the "Packages with dependencies" subsection and their own
# dependencies. These dependent packages are the last ones in their respective
# groups.

# Packages without dependencies
brew 'bootloadhid'
brew 'clang-format'
brew 'dfu-util'

tap 'osx-cross/arm'
brew 'arm-gcc-bin@8', link: true

# Packages with dependencies
brew 'libelf'
brew 'libftdi0'
brew 'libhid'
brew 'avrdude'

brew 'libusb-compat'
brew 'dfu-programmer'

brew 'isl'
brew 'libmpc'
tap 'osx-cross/avr'
brew 'avr-binutils'
brew 'avr-gcc@8', link: true

brew 'teensy_loader_cli'
tap 'qmk/qmk'
brew 'qmk'

# vim: set expandtab shiftwidth=0 tabstop=2:
