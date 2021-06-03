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
cask 'matterhorn'  # Installed using --no-quarantine by script
cask 'microsoft-teams'
cask 'netnewswire'
cask 'openjdk'
#cask 'openzfs'
cask 'qobuz'
cask 'soundsource'
cask 'telegram'
cask 'textual'
cask 'the-unarchiver'
cask 'tunnelblick'
cask 'vagrant'
cask 'vagrant-manager'
cask 'vagrant-vmware-utility'
cask 'virtualbox'
cask 'virtualbox-extension-pack'
cask 'vmware-fusion'
cask 'webex-meetings'
cask 'whatsapp'
cask 'xquartz'
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

brew 'ansible'
brew 'aria2'
brew 'asciinema'
brew 'bat'
brew 'bitwarden-cli'
brew 'bzr'
brew 'curl'
brew 'dialog'
brew 'ffmpeg'
brew 'git'
brew 'gnupg'
brew 'gnuplot'
brew 'htop'
brew 'ipmitool'
brew 'iproute2mac'
brew 'jq'
brew 'juju'
brew 'less'
brew 'libosinfo'
brew 'neovim'
brew 'node'
brew 'pandoc'
brew 'picocom'
brew 'pinentry-mac'
brew 'pyenv'
brew 'rsync'
brew 'sipcalc'
brew 'socat'
brew 'speedtest-cli'
brew 'sshuttle'
brew 'svn'  # Required by font-source-code-pro
brew 'terminal-notifier'
brew 'tree'
brew 'watch'
brew 'wget'
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

# Window manager
tap 'homebrew/services'  # Explicitly tap to keep during `brew bundle cleanup`
tap 'koekeishiya/formulae'
brew 'yabai'
brew 'skhd'

# MongoDB
tap 'mongodb/brew'
brew 'mongodb-database-tools'


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
