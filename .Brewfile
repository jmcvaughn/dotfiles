#-------------------------------------------------------------------------------
# Casks
#-------------------------------------------------------------------------------

tap 'homebrew/cask'  # Explicitly tap to keep during `brew bundle cleanup`
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
cask 'libreoffice'
cask 'libreoffice-language-pack'
cask 'netnewswire'
cask 'qobuz'
cask 'raspberry-pi-imager'
cask 'slack'
cask 'soundsource'
cask 'telegram'
cask 'vagrant'
cask 'vagrant-manager'
cask 'vagrant-vmware-utility'
cask 'virtualbox'  # Required for Vagrant even if unused
cask 'vmware-fusion'
cask 'whatsapp'
cask 'wkhtmltopdf'  # Used by pandoc to create files
cask 'zoom'

# Drivers
tap 'homebrew/cask-drivers'
cask 'linn-konfig'  # Not a driver, here due to Cask rules: https://git.io/fjb4S

# Alternative versions
tap 'homebrew/cask-versions'
cask 'sonos-s1-controller'


#-------------------------------------------------------------------------------
# Fonts
#-------------------------------------------------------------------------------

tap 'homebrew/cask-fonts'
cask 'font-source-code-pro'


#-------------------------------------------------------------------------------
# Homebrew packages
#-------------------------------------------------------------------------------

brew 'aria2'
brew 'asciinema'
brew 'ffmpeg'
brew 'gnupg'
brew 'ipmitool'
brew 'iproute2mac'
brew 'jq'
brew 'mas'
brew 'neovim'
brew 'node'
brew 'pandoc'
brew 'pinentry-mac'
brew 'pyenv'
brew 'rsync'
brew 'sipcalc'
brew 'speedtest-cli'
brew 'svn'  # Required by font-source-code-pro
brew 'tree'
brew 'watch'
brew 'weechat'
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

# Window manager
tap 'homebrew/services'  # Explicitly tap to keep during `brew bundle cleanup`
tap 'koekeishiya/formulae'
brew 'yabai'
brew 'skhd'


#-------------------------------------------------------------------------------
# Mac App Store
#-------------------------------------------------------------------------------

mas '1440147259'  # AdGuard for Safari
mas '1352778147'  # Bitwarden, IIRC only the MAS version has Safari extension
mas '848937349'   # Linn Kazoo
mas '409203825'   # Numbers
mas '409201541'   # Pages
mas '1451685025'  # WireGuard


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
