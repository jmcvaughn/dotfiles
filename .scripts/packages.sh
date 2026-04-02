#!/bin/sh

install_packages() {
	# Check if these applications are already installed. They need to run in
	# order to complete installation; they will only be launched if newly
	# installed.
	cask_before=$(brew cask list soundsource telegram 2> /dev/null)

	# Install packages
	brew bundle --global && hash -r

	# Configure DisplayCAL here as DisplayCAL's calibration settings (transient)
	# are stored here
	displaycal_config="$HOME/Library/Preferences/DisplayCAL/DisplayCAL.ini"
	if [ ! -e "$displaycal_config" ]; then
		mkdir "$(dirname "$displaycal_config")"

		cat <<- 'EOF' > "$displaycal_config"
		[Default]
		argyll.dir = /usr/local/bin
		show_donation_message = 0
		startup_sound.enable = 0
		EOF
	fi

	# If SoundSource newly installed, run Audio Capture Engine installer
	if ! echo "$cask_before" | grep -q SoundSource && brew cask list soundsource > /dev/null 2>&1; then
		sudo /Applications/SoundSource.app/Contents/Resources/aceinstaller install -s
	fi

	# Run Telegram if newly installed, for Share menu extension
	if ! echo "$cask_before" | grep -q Telegram && brew cask list telegram > /dev/null 2>&1; then
		open -a Telegram && sleep 3 && pkill -x Telegram
	fi
}


set_login_items() {
	# Note: AppleScript only uses double quotes

	# Login items
	## Clear all existing login items
	IFS=','
	for item in $(osascript -e 'tell application "System Events" to get the name of every login item' | sed 's/, /,/g'); do
		osascript -e "tell application \"System Events\" to delete login item \"$item\""
	done
	unset IFS

	# Add login items
	## Use separate osascript calls, otherwise you only get output from the last
	## to run and order seems to change
	osascript -e 'tell application "System Events" to make login item at end with properties {name: "LaunchBar", path: "/Applications/LaunchBar.app", hidden: false}' > /dev/null
	osascript -e 'tell application "System Events" to make login item at end with properties {name: "SoundSource", path: "/Applications/SoundSource.app", hidden: true}' > /dev/null
}


main() {
	export HOMEBREW_NO_ANALYTICS=1

	# Install Homebrew
	if ! which brew > /dev/null 2>&1; then
		# Homebrew install command, see https://brew.sh
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		hash -r
	fi

	install_packages
	set_login_items

	# Install QMK
	curl -fsSL https://install.qmk.fm | sh

	# Install OpenTofu completions
	if ! which tofu > /dev/null 2>&1; then
		tofu -install-autocomplete
	fi
}

main

# vim: set filetype=bash foldmethod=syntax:
