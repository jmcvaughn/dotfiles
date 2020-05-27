#!/bin/sh

# Dock > Icon size: 38
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 38

# Dock > Position on screen: Bottom
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM

# Region & Language > Input Sources: English (United Kingdom)
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'gb')]"

# Power > Blank screen: Never
gsettings set org.gnome.desktop.session idle-delay 0

# Disable screensaver
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
