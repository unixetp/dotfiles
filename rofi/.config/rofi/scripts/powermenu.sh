#!/usr/bin/env bash
set -euo pipefail

theme_dir="$HOME/.config/rofi"
theme="$theme_dir/powermenu.rasi"
uptime_text="$(uptime -p | sed 's/^up //')"

shutdown=''
reboot=''
lock=''
suspend=''
logout='󰈆'
yes=''
no=''

choice="$(printf '%s\n' "$lock" "$suspend" "$logout" "$reboot" "$shutdown" | rofi -dmenu -p "Uptime: $uptime_text" -mesg "Uptime: $uptime_text" -theme "$theme")"
[[ -n "$choice" ]] || exit 0

confirmation="$(printf '%s\n' "$yes" "$no" | rofi \
    -theme-str 'window { location: center; anchor: center; fullscreen: false; width: 350px; }' \
    -theme-str 'mainbox { children: [ "message", "listview" ]; }' \
    -theme-str 'listview { columns: 2; lines: 1; }' \
    -theme-str 'element-text { horizontal-align: 0.5; }' \
    -theme-str 'textbox { horizontal-align: 0.5; }' \
    -dmenu -p 'Confirmation' -mesg 'Are you sure?' -theme "$theme")"
[[ "$confirmation" == "$yes" ]] || exit 0

case "$choice" in
    "$lock")
        hyprlock
        ;;
    "$suspend")
        hyprlock &
        sleep 1
        systemctl suspend
        ;;
    "$logout")
        hyprctl dispatch exit
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$shutdown")
        systemctl poweroff
        ;;
esac
