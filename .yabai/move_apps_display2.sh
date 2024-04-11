#!/bin/bash

primary_display_id=$(yabai -m query --displays | jq '.[] | select((.frame.w == 3440 and .frame.h == 1440)) | .id')
secondary_display_id=$(yabai -m query --displays | jq '.[] | select((.frame.w == 1440) and (.frame.h == 3440))| .id')

app_ids=$(yabai -m query --windows | jq '.[] | select((.app == "Slack") or (.app == "WhatsApp") or (.app == "Telegram")) | .id')

if [ "$primary_display_id" ] && [ "$secondary_display_id" ]; then
	for app_id in $app_ids; do
		yabai -m window "$app_id" --display "$secondary_display_id"
	done
fi
