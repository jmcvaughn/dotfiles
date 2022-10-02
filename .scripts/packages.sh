#!/bin/sh

install_packages() {
	# Check if these applications are already installed. They need to run in
	# order to complete installation; they will only be launched if newly
	# installed.
	cask_before=$(brew cask list soundsource telegram 2> /dev/null)
	## LibreOffice Language Pack doesn't install to /Applications/ so this
	## returns nothing to stdout; exit code is sufficient
	brew cask list libreoffice-language-pack &> /dev/null
	lolang_instbefore=$?

	# Install packages
	brew bundle --global --no-lock && hash -r

	# Configure DisplayCAL here as DisplayCAL's calibration settings (transient)
	# are stored here
	displaycal_config="$HOME/Library/Preferences/DisplayCAL/DisplayCAL.ini"
	if [ ! -e "$displaycal_config" ]; then
		gmkdir "$(dirname "$displaycal_config")"

		cat <<- 'EOF' > "$displaycal_config"
		[Default]
		argyll.dir = /usr/local/bin
		show_donation_message = 0
		startup_sound.enable = 0
		EOF
	fi

	# Get LibreOffice Language Pack version and check if newly installed
	lolang_vers="$(brew cask list --versions libreoffice-language-pack 2> /dev/null | gawk 'BEGIN {rc=1} {rc=0; print $2} END {exit rc}')"

	# Run LibreOffice Language Pack installer if newly installed. Also skips if
	# package not in Brewfile.
	if [ "$lolang_instbefore" -ne 0 ] && [ -n "$lolang_vers" ]; then
		# Launching LibreOffice also generates file associations
		open -ja LibreOffice && sleep 5 && pkill -x soffice
		open /usr/local/Caskroom/libreoffice-language-pack/"$lolang_vers"/'LibreOffice Language Pack.app'/
	fi

	# If SoundSource newly installed, run Audio Capture Engine installer
	if ! echo "$cask_before" | ggrep -q SoundSource && brew cask list soundsource > /dev/null 2>&1; then
		sudo /Applications/SoundSource.app/Contents/Resources/aceinstaller install -s
	fi

	# Run Telegram if newly installed, for Share menu extension
	if ! echo "$cask_before" | ggrep -q Telegram && brew cask list telegram > /dev/null 2>&1; then
		open -a Telegram && sleep 3 && pkill -x Telegram
	fi
}


install_vagrant_plugins() {
	installed_vagrant_plugins=$(vagrant plugin list)

	for plugin in vagrant-disksize vagrant-scp vagrant-vmware-desktop; do
		if ! echo  "$installed_vagrant_plugins" | ggrep -q "$plugin"; then
			vagrant plugin install "$plugin"
		fi
	done
}


set_login_items() {
	# Note: AppleScript only uses double quotes

	# Login items
	## Clear all existing login items
	IFS=','
	for item in $(osascript -e 'tell application "System Events" to get the name of every login item' | gsed 's/, /,/g'); do
		osascript -e "tell application \"System Events\" to delete login item \"$item\""
	done
	unset IFS

	# Add login items
	## Use separate osascript calls, otherwise you only get output from the last
	## to run and order seems to change
	osascript -e 'tell application "System Events" to make login item at end with properties {name: "LaunchBar", path: "/Applications/LaunchBar.app", hidden: false}' > /dev/null
	osascript -e 'tell application "System Events" to make login item at end with properties {name: "SoundSource", path: "/Applications/SoundSource.app", hidden: true}' > /dev/null

	# Enable skhd and yabai at login
	brew services start skhd
	brew services start yabai
}


main() {
	export HOMEBREW_NO_ANALYTICS=1

	# Install Homebrew
	if ! which brew > /dev/null 2>&1; then
		# Homebrew install command, see https://brew.sh
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
		hash -r
	fi

	install_packages
	install_vagrant_plugins
	set_login_items
}

main

# vim: set filetype=bash foldmethod=syntax:
