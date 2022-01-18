#!/bin/bash

num_displays=$(yabai -m query --displays | jq '.[-1].index')
focused=$(yabai -m query --windows | jq '.[] | select(."has-focus" == true) | .display')

if [ "$focused" = "$num_displays" ]; then
	yabai -m display --focus 1
else
	yabai -m display --focus $((focused+1))
fi
