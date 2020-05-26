#!/bin/sh

system_preferences() {  # {{{
	#-----------------------------------------------------------------------------
	# General {{{
	#-----------------------------------------------------------------------------

	# System Preferences
	## Appearance: Dark
	defaults write -g AppleInterfaceStyle -string 'Dark'

	## Show scroll bars: Always
	defaults write -g AppleShowScrollBars -string 'Always'

	## Click in the scroll bar to: Jump to the spot that's clicked
	defaults write -g AppleScrollerPagingBehavior -bool true
	# }}}


	#-----------------------------------------------------------------------------
	# Desktop & Screen Saver {{{
	#-----------------------------------------------------------------------------

	# System Preferences
	## Screen Saver > Hot Corners > Bottom Left: Put Display to Sleep
	defaults write com.apple.dock wvous-bl-corner -int 10
	defaults write com.apple.dock wvous-bl-modifier -int 0
	# }}}


	#-----------------------------------------------------------------------------
	# Dock & Menu Bar {{{
	#-----------------------------------------------------------------------------

	# Remove com.apple.controlcenter plist; this will be automatically populated
	defaults delete com.apple.controlcenter 2> /dev/null

	# System Preferences
	## Dock & Menu Bar > Minimise windows using: Scale effect
	defaults write com.apple.dock mineffect -string 'scale'

	## Dock & Menu Bar > Double-click a window's title bar to: minimise
	defaults write -g AppleActionOnDoubleClick -string 'Minimize'

	## Dock & Menu Bar > Automatically hide and show the Dock: True
	defaults write com.apple.dock autohide -bool true

	## Dock & Menu Bar > Show recent applications in Dock: False
	defaults write com.apple.dock show-recents -bool false

	## Dock & Menu Bar > Wi-Fi > Show in Menu Bar: False
	defaults -currentHost write com.apple.controlcenter WiFi -int 8

	## Dock & Menu Bar > Do Not Disturb > Show in Menu Bar: False
	defaults -currentHost write com.apple.controlcenter DoNotDisturb -int 8

	## Screen Mirroring > Show in Menu Bar: False
	defaults write com.apple.airplay showInMenuBarIfPresent -bool false

	## Dock & Menu Bar > Display > Show in Menu Bar: False
	defaults -currentHost write com.apple.controlcenter Display -int 8

	## Dock & Menu Bar > Sound > Show in Menu Bar: False
	defaults -currentHost write com.apple.controlcenter Sound -int 8

	## Battery > Show Percentage: True
	defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

	## Clock:
	##   Date options
	##     Show the day of the week: True  # default
	##     Show date: True
	##   Time options:
	##     Use a 24-hour clock: True  # default
	##     Display the time with seconds: True
	defaults write com.apple.menuextra.clock DateFormat -string 'EEE d MMM	HH:mm:ss'

	## Spotlight > Show in Menu Bar: False
	defaults delete com.apple.Spotlight 'NSStatusItem Visible Item-0' 2> /dev/null
	defaults -currentHost write com.apple.Spotlight MenuItemHidden -bool true

	## Siri > Show in Menu Bar: False
	defaults write com.apple.Siri StatusMenuVisible -bool false

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
	# Mission Control {{{
	#-----------------------------------------------------------------------------

	# System Preferences
	## Automatically rearrange Spaces based on most recent use: False
	defaults write com.apple.dock mru-spaces -bool false

	## When switching to an application, switch to a Space with open windows for the
	## application: False
	defaults write -g AppleSpacesSwitchOnActivate -bool false

	## Group windows by application: True
	defaults write com.apple.dock expose-group-apps -bool true
	# }}}


	#-----------------------------------------------------------------------------
	# Accessibility {{{
	#-----------------------------------------------------------------------------

	# System Preferences
	# Pointer Control > Spring-loading delay: Short
	defaults write -g com.apple.springing.delay -float 0

	## Pointer Control > Mouse & Trackpad > Trackpad Options > Enable dragging: three finger drag
	defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
	# }}}


	#-----------------------------------------------------------------------------
	# Sound {{{
	#-----------------------------------------------------------------------------

	# System Preferences
	## Sound Effects > Play sound on startup: False
	sudo nvram StartupMute=%01

	## Sound Effects > Play user interface sound effects: False
	defaults write -g com.apple.sound.uiaudio.enabled -int 0
	# }}}


	#-----------------------------------------------------------------------------
	# Keyboard {{{
	#-----------------------------------------------------------------------------

	# System Preferences
	## Keyboard > Key repeat: Fastest, Delay Until Repeat: Shortest
	defaults write -g InitialKeyRepeat -int 15  # Seems to adjust both
	defaults write -g KeyRepeat -int 2  # Seems to always be set to 2

	## Keyboard > Customise Control Strip: Mute, Volume Slider, Brightness Slider, Night Shift
	controlstrip_plist="$HOME/Library/Preferences/com.apple.controlstrip.plist"
	/usr/libexec/PlistBuddy -c 'Delete :MiniCustomized' "$controlstrip_plist" > /dev/null 2>&1
	/usr/libexec/PlistBuddy -c 'Add :MiniCustomized array' "$controlstrip_plist"
	for item in mute volume brightness night-shift; do
		/usr/libexec/PlistBuddy -c "Add :MiniCustomized: string com.apple.system.$item" "$controlstrip_plist"
	done

	## Text > Correct spelling automatically: False
	defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false

	## Text > Capitalise word automatically: False
	defaults write -g NSAutomaticCapitalizationEnabled -bool false

	## Text > Add full stop with double space: False
	defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false

	## Text > Touch Bar typing suggestions: False
	defaults write -g NSAutomaticTextCompletionEnabled -bool false

	## Text > Use smart quotes and dashes: False
	defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
	defaults write -g NSAutomaticDashSubstitutionEnabled -bool false

	## Shortcuts > Use keyboard navigation to move focus between controls: True
	defaults write -g AppleKeyboardUIMode -int 2
	# }}}


	#-----------------------------------------------------------------------------
	# Trackpad {{{
	#-----------------------------------------------------------------------------

	# System Preferences
	## Point & Click > Click: Light
	defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
	defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 0

	## Point & Click > Tracking speed: 5
	defaults write -g com.apple.trackpad.scaling -float 0.875

	## More Gestures > Swipe between full-screen apps: Swipe left or right with four fingers
	defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2
	defaults -currentHost write -g com.apple.trackpad.fourFingerHorizSwipeGesture -int 2

	## More Gestures > Mission Control: Swipe up with four fingers
	defaults write com.apple.dock showMissionControlGestureEnabled -bool true

	## More Gestures > Launchpad: False
	defaults write com.apple.dock showLaunchpadGestureEnabled -bool false
	# }}}


	#-----------------------------------------------------------------------------
	# Mouse {{{
	#-----------------------------------------------------------------------------

	# System Preferences
	## Tracking speed: Slowest (eliminates acceleration but slows tracking)
	defaults write -g com.apple.mouse.scaling -float 0

	## Scrolling speed: Slowest (eliminates acceleration but slows tracking)
	defaults write -g com.apple.scrollwheel.scaling -float 0
	# }}}


	#-----------------------------------------------------------------------------
	# Energy Saver {{{
	#-----------------------------------------------------------------------------

	# System Preferences
	## Battery > Turn display off after: 5 minutes
	sudo pmset -b displaysleep 5
	sudo pmset -b sleep 5

	## Battery > Slightly dim the display while on battery power: False
	sudo pmset -b lessbright 0

	## Power Adapter > Turn display off after: 15 minutes
	sudo pmset -c displaysleep 15

	## Power Adapter > Prevent computer from sleeping automatically when the display is off: True
	sudo pmset -c sleep 0
	# }}}
}  # }}}


other_preferences(){  # {{{
	# Disable special key pop-up on press-and-hold
	defaults write -g ApplePressAndHoldEnabled -bool false

	# Expand panels
	defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
	defaults write -g NSNavPanelExpandedStateForSaveMode2 -bool true
	defaults write -g PMPrintingExpandedStateForPrint -bool true
	defaults write -g PMPrintingExpandedStateForPrint2 -bool true

	# Unhide /Volumes/
	sudo chflags nohidden /Volumes/

	# Enable Touch ID for sudo
	if ! ggrep -qE '^auth[[:space:]]*sufficient[[:space:]]*pam_tid.so$' /etc/pam.d/sudo; then
		sudo gsed -i '/# sudo: auth account password session/ a auth       sufficient     pam_tid.so' /etc/pam.d/sudo
	fi

	# Disable "Do you want to use <VOLUME> to back up with Time Machine?" prompt
	defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
}  # }}}


main() {  # {{{
	system_preferences
	other_preferences
}  # }}}

main

# vim: set filetype=bash foldmethod=marker:
