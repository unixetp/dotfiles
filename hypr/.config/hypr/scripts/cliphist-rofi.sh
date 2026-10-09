#!/usr/bin/env bash

chosen=$(cliphist list | rofi -dmenu -p "Clipboard" -theme ~/.config/rofi/launcher.rasi)

if [ -n "$chosen" ]; then
    echo "$chosen" | cliphist decode | wl-copy
    YDOTOOL_SOCKET="/run/user/$(id -u)/.ydotool_socket" ydotool key 29:1 47:1 47:0 29:0
fi
