#!/bin/bash

slack_window=$(yabai -m query --windows | jq '.[] | select(."app" == "Slack")')
focused=$(echo "$slack_window" | awk -F ': ' '/"has-focus"/ { gsub(",", ""); print $2 }')
window_id=$(echo "$slack_window" | awk -F ': ' '/"id"/ { gsub(",", ""); print $2 }')

if [ "$slack_window" ]; then
	case $focused in
		'true') skhd -k 'cmd - h' ;;
		'false') yabai -m window --focus "$window_id" ;;
	esac
else
	open /Applications/Slack.app/
fi
