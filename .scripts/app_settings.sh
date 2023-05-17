#!/bin/sh

calculator() {
	# Menu options
	## View > Show Thousands Separators: True
	defaults write com.apple.calculator SeparatorsDefaultsKey -bool true

	## Window > Show Paper Tape: True
	defaults write com.apple.calculator PaperTapeVisibleDefaultsKey -bool true
}


calendar() {
	# Settings
	## General > Day starts at: 09:00
	defaults write com.apple.iCal 'first minute of work hours' -int 540

	## General > Show Birthdays calendar: False
	defaults write com.apple.iCal 'add holiday calendar' -bool false

	## General > Show Holidays calendar: False
	defaults write com.apple.iCal 'display birthdays calendar' -bool false

	## Advanced: Turn on time zone support: True
	defaults write com.apple.iCal 'TimeZone support enabled' -bool true

	## Advanced > Show week numbers: True
	defaults write com.apple.iCal 'Show Week Numbers' -bool true

	# View menu options
	## Show Calendar List: True
	defaults write com.apple.iCal CalendarSidebarWidth -float 180  # default, custom value doesn't work
	defaults write com.apple.iCal CalendarSidebarShown -bool true

	## Show Declined Events: True
	defaults write com.apple.iCal showDeclinedEvents -bool true

	# Other
	## Skip privacy pane (required for "Show Calendar List" to work)
	defaults write com.apple.iCal privacyPaneHasBeenAcknowledgedVersion -int 4

	## Collapse "Other" section in calendar list
	defaults write com.apple.iCal CollapsedTopLevelNodes -dict 'MainWindow' '(Other)'
}


finder() {
	# Finder Settings
	## General > Show these items on the desktop
	defaults write com.apple.finder ShowMountedServersOnDesktop -bool true

	## General > New Finder windows show: user home
	defaults write com.apple.finder NewWindowTarget -string 'PfHm'
	defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME"

	## Advanced > Show all filename extensions: True
	defaults write -g AppleShowAllExtensions -bool true

	## Advanced > Show warning before changing an extension: False
	defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

	## Advanced > Show warning before removing from iCloud Drive
	defaults write com.apple.finder FXEnableRemoveFromICloudDriveWarning -bool false

	## Advanced > Show warning before emptying the Bin: False
	defaults write com.apple.finder WarnOnEmptyTrash -bool false

	## Advanced > When performing a search: Search the Current Folder
	defaults write com.apple.finder FXDefaultSearchScope -string 'SCcf'

	# View menu options
	## Show Tab Bar: True
	defaults write com.apple.finder NSWindowTabbingShoudShowTabBarKey-com.apple.finder.TBrowserWindow -bool true

	## For icon and list views only; column view is set as part of ColumnViewOptions
	defaults write com.apple.finder ShowPreviewPane -bool false  # default
	defaults write com.apple.finder ShowSidebar -bool true  # default
	defaults write com.apple.finder ShowStatusBar -bool true

	# Other
	## Expand info pane sections
	### Get Info window sections:
	### MetaData: 'More Info'
	### Name: 'Name & Extension'
	### Privileges: 'Sharing & Permissions'
	defaults write com.apple.finder FXInfoPanesExpanded -dict \
		General -bool true \
		MetaData -bool false \
		Name -bool false \
		Comments -bool false \
		OpenWith -bool false \
		Preview -bool false \
		Privileges -bool true

	## Default to column view
	defaults write com.apple.finder FXPreferredViewStyle -string 'clmv'
	defaults write com.apple.finder SearchRecentsSavedViewStyle -string 'clmv'  # Recents

	## Collapse Tags section in sidebar
	defaults write com.apple.finder SidebarTagsSctionDisclosedState -bool false

	## Disable .DS_Store file creation on network and USB volumes
	defaults write com.apple.desktopservices DSDontWriteNetworkStores true
	defaults write com.apple.desktopservices DSDontWriteUSBStores true
}


iina() {
	# Settings
	## General > When launched: Do nothing
	defaults write com.colliderli.iina actionAfterLaunch -int 2

	## General > Receive beta updates: False (suppresses prompt on first launch)
	defaults write com.colliderli.iina receiveBetaUpdate -bool false
}


launchbar() {
	# Settings
	## General > Open Location > Prefer secure URL schemes: True
	defaults write at.obdev.LaunchBar OpenLocationPreferSecureSchemes -bool true

	## General > Open Location > Automatically prefix hostname with 'www': False
	defaults write at.obdev.LaunchBar OpenLocationPrependWWW -bool false

	## Appearance > Theme: Dark
	defaults write at.obdev.LaunchBar Theme -string 'at.obdev.LaunchBar.theme.Dark'

	## Shortcuts > Keyboard Shortcuts > Search in Spotlight: False
	defaults write at.obdev.LaunchBar SpotlightHotKeyEnabled -bool false

	## Shortcuts > Modifier Taps > Instant Send: Double Command
	defaults write at.obdev.LaunchBar ModifierTapInstantSend -int 21

	## Shortcuts > Browsing > Instant Info Browsing: True
	defaults write at.obdev.LaunchBar InstantInfoBrowsing -bool true

	## Actions > Options > Preferred Terminal application: iTerm
	defaults write at.obdev.LaunchBar PreferredTerminal -int 1

	## Advanced > Show Dock Icon: False
	defaults write at.obdev.LaunchBar ShowDockIcon -bool false

	# Other
	## Set user defaults version (otherwise theme needs to be set manually)
	defaults write at.obdev.LaunchBar UserDefaultsVersion -int 6

	## Skip welcome screen
	defaults write at.obdev.LaunchBar WelcomeWindowVersion -int 2
	
	## Copy custom snippets
	mkdir -p "$HOME/Library/Application Support/LaunchBar/Snippets/" 2> /dev/null
	cp "$(gdirname "$0")"/launchbar_snippets/* "$HOME/Library/Application Support/LaunchBar/Snippets/"
}


mimestream() {
	# Settings
	## General > Text Size: 3
	defaults write com.mimestream.Mimestream TextSizeAdjustment -int -1

	## Composing > Undo Send Delay: 20 seconds
	defaults write com.mimestream.Mimestream SendCancellationDuration -int 20

	## Labs > Client-side Snoozing: True
	defaults write com.mimestream.Mimestream enableSnoozing -bool true
}


netnewswire() {
	# Settings
	## General > Article Text Size: Medium
	defaults write com.ranchero.NetNewsWire-Evergreen articleTextSize -int 2
}


notes() {
	# Settings
	## Automatically sort ticked items: True
	defaults write com.apple.Notes ICChecklistAutoSortEnabledDefaultsKey -bool true
}


pages() {
	# Menu options
	## View > Show Tab Bar: True
	defaults write com.apple.iWork.Pages NSWindowTabbingShoudShowTabBarKey-TPMacDocumentWindow-TPAdaptiveDocumentWindowController-TPAdaptiveDocumentWindowController-VT-FS -bool true
}


preview() {
	# Menu options
	## View > Show Tab Bar: True
	defaults write com.apple.Preview NSWindowTabbingShoudShowTabBarKey-PVWindow-PVWindowController-PVWindowController-VT-FS -bool true
}


safari() {
	# Settings
	## General > Open "safe" files after downloading: False
	defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

	## General > Remove download list items: When Safari quits
	defaults write com.apple.Safari DownloadsClearingPolicy -int 1

	## AutoFill > Using information from my contacts: False
	defaults write com.apple.Safari AutoFillFromAddressBook -bool false

	## AutoFill > Usernames and passwords: False
	defaults write com.apple.Safari AutoFillPasswords -bool false

	## AutoFill > Credit cards: False
	defaults write com.apple.Safari AutoFillCreditCardData -bool false

	## AutoFill > Other forms: False
	defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false

	## Search > Search engine: DuckDuckGo
	defaults write com.apple.Safari SearchProviderIdentifier -string 'com.duckduckgo'

	## Search > Enable Quick Website search
	defaults write com.apple.Safari WebsiteSpecificSearchEnabled -bool false

	# Menu options
	## View > Show Tab Bar: True
	defaults write com.apple.Safari AlwaysShowTabBar -bool true

	## View > Show status bar: True
	defaults write com.apple.Safari ShowOverlayStatusBar -bool true

	# Other
	## Toolbar: Sidebar, Back/Forward, Flexible Space, Address and Search, Privacy Report, AdGuard for Safari, Flexible Space, Share
	defaults write com.apple.Safari 'NSToolbar Configuration BrowserStandaloneTabBarToolbarIdentifier' -dict 'TB Item Identifiers' '(
		SidebarToolbarIdentifier,
		BackForwardToolbarIdentifier,
		NSToolbarFlexibleSpaceItem,
		InputFieldsToolbarIdentifier,
		PrivacyReportToolbarIdentifier,
		"com.adguard.safari.AdGuard.Extension (TC3Q7MAJXF) Button",
		NSToolbarFlexibleSpaceItem,
		ShareToolbarIdentifier
	)'
	defaults write com.apple.Safari 'OrderedToolbarItemIdentifiers' -array \
		'SidebarToolbarIdentifier' \
		'BackForwardToolbarIdentifier' \
		'NSToolbarFlexibleSpaceItem' \
		'InputFieldsToolbarIdentifier' \
		'PrivacyReportToolbarIdentifier' \
		"'com.adguard.safari.AdGuard.Extension (TC3Q7MAJXF) Button'" \
		'NSToolbarFlexibleSpaceItem' \
		'ShareToolbarIdentifier'
}


soundsource() {
	# Settings
	## Audio > Super Volume Keys: True
	defaults write com.rogueamoeba.soundsource keyboardVolume -bool true

	## Appearance > Follow System Accent Color: True
	defaults write com.rogueamoeba.soundsource followSystemAccent -bool true
}


textedit() {
	# View menu options
	## Show Tab Bar: True
	defaults write com.apple.TextEdit NSWindowTabbingShoudShowTabBarKey-NSWindow-DocumentWindowController-DocumentWindowController-VT-FS -bool true
}


vagrant_manager() {
	# Preferences
	## Terminal Preference: iTerm/iTerm2
	defaults write lanayo.Vagrant-Manager terminalPreference -string 'iTerm'

	## Terminal Editor Preference: vim
	defaults write lanayo.Vagrant-Manager terminalEditorPreference -string 'vim'

	## Status Bar Icon Theme: Flat
	defaults write lanayo.Vagrant-Manager statusBarIconTheme -string 'flat'

	## Halt machines on exit: True
	defaults write lanayo.Vagrant-Manager haltOnExit -bool true

	## Don't show task windows: True
	defaults write lanayo.Vagrant-Manager hideTaskWindows -bool true

	## Refresh every: 1 minute
	defaults write lanayo.Vagrant-Manager refreshEvery -bool true
	defaults write lanayo.Vagrant-Manager refreshEveryInterval -int 60

	## Show task notifications: True
	defaults write lanayo.Vagrant-Manager showTaskNotification -bool true

	## Send anonymous profile data: False
	defaults write lanayo.Vagrant-Manager sendProfileData -bool false
}


vmware_fusion() {
	# Settings
	## General > Applications menu > Show in menu bar: Never
	defaults write com.vmware.fusion showStartMenu3 -int 0

	# Menu options
	## View > Show Tab Bar: True
	defaults write com.vmware.fusion NSWindowTabbingShoudShowTabBarKey-PLFSMWindow-PLFSMWindowProvider-PLVMWindowController-HT-FS -bool true
}


main() {
	calculator
	pkill -x Calculator && open -a Calculator

	calendar
	pkill -x Calendar && open -a Calculator

	finder
	pkill -x Finder

	iina
	pkill -x IINA

	launchbar
	pkill -x LaunchBar && open -a LaunchBar

	mimestream
	pkill -x Mimestream && open -a Mimestream

	netnewswire
	pkill -x NetNewsWire && open -a NetNewsWire

	if ! pgrep -qx Notes; then
		open -a Notes
		sleep 5
		pkill -x Notes
	fi
	notes
	pkill -x Notes && open -a Notes

	pages
	pkill -x Pages && open -a Pages

	preview
	pkill -x Preview && open -a Preview

	# Start Safari if not running to create fresh plist; required for toolbar
	# configuration
	if ! pgrep -qx Safari; then
		open -a Safari
		sleep 5
		pkill -x Safari
	fi
	safari
	pkill -x Safari && sleep 1 && open -a Safari

	soundsource
	pkill -x soundsource && open -a SoundSource

	textedit
	pkill -x TextEdit && open -a 'TextEdit'

	vagrant_manager
	pkill -x 'Vagrant Manager' && open -a 'Vagrant Manager'

	vmware_fusion
	if pkill -x 'VMware Fusion'; then
		open -a 'VMware Fusion' 2> /dev/null || open -a 'VMware Fusion Tech Preview'
	fi
}

main

# vim: set filetype=bash foldmethod=syntax:
