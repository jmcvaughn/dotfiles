#!/usr/bin/env bash

# See: https://nikitabobko.github.io/AeroSpace/commands#focus-back-and-forth
#      https://nikitabobko.github.io/AeroSpace/commands#workspace-back-and-forth
if ! aerospace focus-back-and-forth; then
	aerospace workspace-back-and-forth
fi
