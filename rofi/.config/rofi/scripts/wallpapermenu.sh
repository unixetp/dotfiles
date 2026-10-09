#!/bin/bash

wallpaper_dir="$HOME/Pictures/Wallpapers"

find "$wallpaper_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.gif" \) -print0 | \
while IFS= read -r -d $'\0' file; do
    printf "%s\0icon\x1f%s\n" "$(basename "$file")" "$file"
done | \
rofi -dmenu -i -p "wallpaper" -markup-rows -width 40 -lines 15 -theme ~/.config/rofi/wallpaper-switcher.rasi | \
while IFS= read -r selected_wallpaper; do
  if [[ -n "$selected_wallpaper" ]]; then
    full_path="$wallpaper_dir/$selected_wallpaper"
    "$HOME/.config/hypr/setwallpaper.sh" "$full_path"
  fi
done
