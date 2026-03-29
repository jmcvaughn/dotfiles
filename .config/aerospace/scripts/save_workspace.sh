#!/bin/sh

workspace=$(aerospace list-workspaces --focused)

if [ "$workspace" != 'Toggled' ]; then
	echo "$workspace" > /tmp/workspace
fi
