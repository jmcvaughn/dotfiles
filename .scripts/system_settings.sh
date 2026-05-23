#!/bin/sh

set -x

system_settings() {  # {{{
	#-----------------------------------------------------------------------------
	# Accessibility {{{
	#-----------------------------------------------------------------------------

	# System Settings
	# Pointer Control > Spring-loading speed: Fastest
	defaults write -g com.apple.springing.delay -float 0

	## Pointer Control > Mouse & Trackpad > Trackpad Options > Use trackpad for dragging: True
	## Pointer Control > Mouse & Trackpad > Trackpad Options > Dragging style: Three-Finger Drag
	defaults -currentHost write -g com.apple.trackpad.threeFingerDragGesture -bool true
	defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
	# }}}


	#-----------------------------------------------------------------------------
	# Appearance {{{
	#-----------------------------------------------------------------------------

	# System Settings
	## Appearance: Dark
	defaults write -g AppleInterfaceStyle -string 'Dark'

	## Tint window background with wallpaper colour: False
	defaults write -g AppleReduceDesktopTinting -bool true

	## Show scroll bars: Always
	defaults write -g AppleShowScrollBars -string 'Always'

	## Click in the scroll bar to: Jump to the spot that's clicked
	defaults write -g AppleScrollerPagingBehavior -bool true
	# }}}


	#-----------------------------------------------------------------------------
	# Desktop & Dock {{{
	#-----------------------------------------------------------------------------

	# System Settings
	## Dock > Size: 80
	defaults write com.apple.dock tilesize -float 80

	## Dock > Minimise windows using: Scale effect
	defaults write com.apple.dock mineffect -string 'scale'

	## Dock > Double-click a window's title bar to: Minimise
	defaults write -g AppleActionOnDoubleClick -string 'Minimize'

	## Dock > Automatically hide and show the Dock: True
	defaults write com.apple.dock autohide -bool true

	## Dock > Show suggested and recent apps in Dock: False
	defaults write com.apple.dock show-recents -bool false

	## Windows > Drag windows to left or right edge of screen to tile: False
	defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false

	## Windows > Drag windows to menu bar to fill screen: False
	defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false

	## Windows > Hold Option key while dragging windows to tile: False
	defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool false

	## Mission Control > Automatically rearrange Spaces based on most recent use: False
	defaults write com.apple.dock mru-spaces -bool false

	## Mission Control > When switching to an application, switch to a Space with open windows for the application: False
	defaults write -g AppleSpacesSwitchOnActivate -bool false

	## Mission Control > Group windows by application: True
	defaults write com.apple.dock expose-group-apps -bool true

	## Hot Corners > Bottom Right: False
	defaults write com.apple.dock wvous-br-corner -int 1

	# Other
	## Remove delay showing the Dock
	defaults write com.apple.dock autohide-delay -float 0

	## Disable show/hide animation
	defaults write com.apple.dock autohide-time-modifier -float 0

	## Make icons of hidden applications transparent
	defaults write com.apple.dock showhidden -bool true

	## Remove icons
	defaults write com.apple.dock persistent-apps -array
	defaults write com.apple.dock persistent-others -array
	# }}}


	#-----------------------------------------------------------------------------
	# Displays {{{
	#-----------------------------------------------------------------------------

	## Advanced > Slightly dim the display while on battery: False
	sudo pmset -b lessbright 0

	## Advanced > Prevent computer from sleeping automatically on power adapter when the display is off: True
	sudo pmset -c sleep 0
	# }}}


	#-----------------------------------------------------------------------------
	# Menu Bar {{{
	#-----------------------------------------------------------------------------

	# System Settings
	## Menu Bar Controls > Clock > Clock Options > Show the day of the week: True
	### Should be default on fresh install but not if dict is deleted
	defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true

	## Menu Bar Controls > Clock > Clock Options > Show date: True
	### Used to be 0 (When Space Allows)
	defaults write com.apple.menuextra.clock ShowDate -int 1

	## Menu Bar Controls > Clock > Clock Options > Display the time with seconds: True
	defaults write com.apple.menuextra.clock ShowSeconds -bool true
	# }}}


	#-----------------------------------------------------------------------------
	# Sound {{{
	#-----------------------------------------------------------------------------

	# System Settings
	## Sound Effects > Alert volume: 50%
	defaults write -g com.apple.sound.beep.volume -float 0.6065307

	## Sound Effects > Play sound on startup: False
	sudo nvram StartupMute=%01

	## Sound Effects > Play user interface sound effects: False
	defaults write -g com.apple.sound.uiaudio.enabled -int 0
	# }}}


	#-----------------------------------------------------------------------------
	# Lock Screen {{{
	#-----------------------------------------------------------------------------

	# System Settings
	## Turn display off on battery when active: For 5 minutes
	sudo pmset -b displaysleep 5
	sudo pmset -b sleep 5

	## Turn display off on power adapter when inactive: For 15 minutes (custom)
	sudo pmset -c displaysleep 15
	# }}}


	#-----------------------------------------------------------------------------
	# Keyboard {{{
	#-----------------------------------------------------------------------------

	# System Settings
	## Key repeat: Fastest, Delay Until Repeat: Shortest
	defaults write -g InitialKeyRepeat -int 15  # Seems to adjust both
	defaults write -g KeyRepeat -int 2  # Seems to always be set to 2

	## Keyboard navigation: True
	defaults write -g AppleKeyboardUIMode -int 2

	## Text Input > Input Sources > Edit > All Input Sources > Correct spelling automatically: False
	defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
	defaults write -g WebAutomaticSpellingCorrectionEnabled -bool false

	## Text Input > Input Sources > Edit > All Input Sources > Capitalise words automatically: False
	defaults write -g NSAutomaticCapitalizationEnabled -bool false

	## Text Input > Input Sources > Edit > All Input Sources > Add full stop with double space: False
	defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false

	## Text Input > Input Sources > Edit > All Input Sources > Use smart quotes and dashes: False
	defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
	defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
	# }}}


	#-----------------------------------------------------------------------------
	# Trackpad {{{
	#-----------------------------------------------------------------------------

	# System Settings
	## Point & Click > Tracking speed: 5
	defaults write -g com.apple.trackpad.scaling -float 0.875

	## Point & Click > Click: Light
	defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
	defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 0

	## Point & Click > Quiet Click: True
	defaults write com.apple.AppleMultitouchTrackpad ActuationStrength -int 0

	## Point & Click > Tap to click: False
	defaults -currentHost write -g com.apple.mouse.tapBehavior -int 0
	defaults write com.apple.AppleMultitouchTrackpad Clicking -bool false
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool false

	## More Gestures > Swipe between full-screen applications: Swipe Left or Right with Four Fingers
	defaults -currentHost write -g com.apple.trackpad.fourFingerHorizSwipeGesture -int 2
	defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerHorizSwipeGesture -int 2

	## More Gestures > Mission Control: Swipe Up with Four Fingers
	defaults -currentHost write -g com.apple.trackpad.fourFingerVertSwipeGesture -int 2
	defaults write com.apple.MultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int 2
	defaults write com.apple.dock showMissionControlGestureEnabled -bool true

	## More Gestures > App Expose: Swipe Down with Four Fingers
	defaults -currentHost write -g com.apple.trackpad.fourFingerVertSwipeGesture -int 2
	defaults write com.apple.MultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int 2
	defaults write com.apple.dock showAppExposeGestureEnabled -bool true
	# }}}


	#-----------------------------------------------------------------------------
	# Mouse {{{
	# Only appears when a mouse is connected
	#-----------------------------------------------------------------------------

	# System Settings
	## Tracking speed: Slowest (eliminates acceleration but slows tracking)
	defaults write -g com.apple.mouse.scaling -float 0

	## Scrolling speed: Slowest (eliminates acceleration but slows tracking)
	defaults write -g com.apple.scrollwheel.scaling -float 0
	# }}}
}  # }}}


other_settings(){  # {{{
	# Disable special key pop-up on press-and-hold
	defaults write -g ApplePressAndHoldEnabled -bool false

	# Expand "Save" panel for all applications
	defaults write -g NSNavPanelExpandedStateForSaveMode -bool true

	# Unhide /Volumes/
	sudo chflags nohidden /Volumes/

	# Enable Touch ID for sudo
	if ! ggrep -qE '^auth[[:space:]]*sufficient[[:space:]]*pam_tid.so$' /etc/pam.d/sudo; then
		sudo gsed -i '/# sudo: auth account password session/ a auth       sufficient     pam_tid.so' /etc/pam.d/sudo
	fi

	# Disable "Do you want to use <VOLUME> to back up with Time Machine?" prompt
	defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

	# Move windows by holding Cmd + Ctrl + drag
	defaults write -g NSWindowShouldDragOnGesture -bool true

	# Add Google DNS network location
	networksetup -createlocation 'Google DNS' populate
	networksetup -switchtolocation 'Google DNS'
	networksetup -setdnsservers 'Wi-Fi' 8.8.8.8 8.8.4.4
	networksetup -switchtolocation Automatic
}  # }}}


main() {  # {{{
	system_settings
	other_settings
}  # }}}

main

# vim: set filetype=bash foldmethod=marker:
