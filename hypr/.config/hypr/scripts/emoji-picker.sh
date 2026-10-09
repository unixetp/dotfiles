#!/usr/bin/env bash

rofi -modi emoji -show emoji -theme ~/.config/rofi/emoji.rasi

sleep 0.15
YDOTOOL_SOCKET="/run/user/$(id -u)/.ydotool_socket" ydotool key 29:1 47:1 47:0 29:0
