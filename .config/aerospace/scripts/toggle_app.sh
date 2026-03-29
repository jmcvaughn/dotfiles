#!/bin/sh

app=$1

open_apps=$(aerospace list-apps &)
last_window=$(cat /tmp/"$app"_last_focused_window &)

focused_workspace=$(aerospace list-workspaces --focused &)
focused_window=$(aerospace list-windows --focused &)
wait
focused_window_id=$(echo "$focused_window" | awk '{ print $1 }' &)
focused_app=$(echo "$focused_window" | awk '{ print $3 }' &)

# If app is open, get app_bundle_id and opened windows
if echo "$open_apps" | grep -q "$app"; then
	app_bundle_id=$(aerospace list-apps | awk "/$app/ { print \$3 }")
	app_windows=$(aerospace list-windows --monitor all --app-bundle-id "$app_bundle_id")
fi

# If app has any windows open
if [ "$app_windows" ]; then
	# If app already focused in "Toggled" workspace, switch back to last workspace
	if [ "$focused_app" = "$app" ] && [ "$focused_workspace" = 'Toggled' ]; then
		aerospace workspace "$(cat /tmp/workspace)"

	# If already focused, save window ID then move it to "Toggled" workspace
	elif [ "$focused_app" = "$app" ]; then
		echo "$focused_window_id" > /tmp/"$app"_last_focused_window &
		aerospace move-node-to-workspace --window-id "$focused_window_id" 'Toggled'

	# Else if the app is not currently focused; open last focused window of app
	elif [ "$last_window" ]; then
		if ! aerospace move-node-to-workspace --focus-follows-window --fail-if-noop --window-id "$last_window" "$focused_workspace"; then
			# `focus` command is separate to cater for the case where window is already in
			# the focused workspace
			aerospace focus --window-id "$last_window"
		fi

	# If last focused window is not known, just open the app
	else
		open /Applications/"$app".app/
	fi

# If app doesn't have any open windows
else
	open /Applications/"$app".app/
fi
