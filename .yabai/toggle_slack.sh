#!/bin/bash

windows=$(yabai -m query --windows)
focused=$(echo "$windows" | jq '.[] | select(."app" == "Slack") | ."has-focus"')
slack_window_id=$(echo "$windows" | jq '.[] | select(."app" == "Slack") | ."id"')

if [ "$slack_window_id" ]; then
	if ! [ "$focused" = 'true' ]; then
		yabai -m window --focus "$slack_window_id"
	else
		osascript -e 'tell application "Finder" to set visible of every process whose frontmost is true to false'
	fi
else
	open /Applications/Slack.app/
fi
