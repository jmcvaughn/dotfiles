#!/bin/sh

move_all_app_windows_to_workspace() {
	for id in $app_windows_ids; do
		aerospace move-node-to-workspace --window-id "$id" "$1"
	done
}

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
	app_windows_ids=$(aerospace list-windows --monitor all --app-bundle-id "$app_bundle_id" | awk '{ print $1 }')
fi

# If app has any windows open
if [ "$app_windows_ids" ]; then

	# If app is focused
	if [ "$focused_app" = "$app" ]; then
		# Save app's currently focused window for toggling
		echo "$focused_window_id" > /tmp/"$app"_last_focused_window &

		if [ "$focused_workspace" = 'Toggled' ]; then
			# If in "Toggled" workspace, switch back to previous workspace
			aerospace workspace "$(cat /tmp/workspace)"
		else
			# Move all of app's windows back to "Toggled" workspace
			move_all_app_windows_to_workspace 'Toggled'
		fi

	# Else if the app is not focused, move all app's windows to focused workspace
	# and focus last focused window of app
	elif [ "$last_window" ]; then
		move_all_app_windows_to_workspace "$focused_workspace"
		# `focus` command is separate to cater for the case where window is already
		# in the focused workspace and/or where app has multiple windows open
		aerospace focus --window-id "$last_window"

	# If last focused window is not known, just move all app's windows to current
	# workspace and focus the first of them
	else
		move_all_app_windows_to_workspace "$focused_workspace"
		aerospace focus --window-id "$(echo "$app_windows_ids" | head -n 1)"
	fi

# If app doesn't have any open windows
else
	open /Applications/"$app".app/
fi
