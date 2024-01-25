#!/bin/bash

app=$1

app_windows=$(yabai -m query --windows | jq ".[] | select(.\"app\" == \"$app\")")
app_focused_window_id=$(echo "$app_windows" | jq 'select(."has-focus" == true) | .id')

if [ "$app_windows" ]; then
	if [ "$app_focused_window_id" ]; then
		echo "$app_focused_window_id" > /tmp/"$app"_last_focused_window
		skhd -k 'cmd - h'
	else
		yabai -m window --focus "$(cat /tmp/"$app"_last_focused_window)"
	fi
else
	open /Applications/"$app".app/
fi
