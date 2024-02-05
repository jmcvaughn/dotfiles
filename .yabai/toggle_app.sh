#!/bin/bash

app=$1

app_windows=$(yabai -m query --windows | jq ".[] | select(.\"app\" == \"$app\")")
app_focused_window_id=$(echo "$app_windows" | jq 'select(."has-focus" == true) | .id')
last_window=$(cat /tmp/"$app"_last_focused_window)

# If app has any windows open
if [ "$app_windows" ]; then
	# If already focused, hide and save last focused window
	if [ "$app_focused_window_id" ]; then
		echo "$app_focused_window_id" > /tmp/"$app"_last_focused_window
		skhd -k 'cmd - h'

	# Otherwise the app is not currently focused; open last focused window of app
	elif [ "$last_window" ]; then
		yabai -m window --focus "$last_window"

	# If last focused window is not known (e.g. Command-H has been used rather
	# than the skhd shortcut, circumventing this script and thus not saving the
	# last window), just open the app
	else
		open /Applications/"$app".app/
	fi

# If app doesn't have any open windows
else
	open /Applications/"$app".app/
fi
