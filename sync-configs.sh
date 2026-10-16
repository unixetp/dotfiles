#!/usr/bin/env bash
set -euo pipefail

repo_dir="${1:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$HOME/.config" "$HOME/Pictures/Wallpapers" "$backup_dir"
cp -an -- "$repo_dir"/wallpapers/. "$HOME/Pictures/Wallpapers/"
shopt -s dotglob nullglob

if [[ -d "$repo_dir/.config" ]]; then
    config_sources=("$repo_dir"/.config/*)
else
    config_sources=()
    for dir in "$repo_dir"/*/; do
        if [[ -d "$dir/.config" ]]; then
            config_sources+=("$dir"/.config/*)
        fi
    done
fi

for source in "${config_sources[@]}"; do
    name="${source##*/}"
    target="$HOME/.config/$name"
    if [[ -e "$target" || -L "$target" ]]; then
        mv -- "$target" "$backup_dir/"
    fi
    cp -a -- "$source" "$target"
done

for file in .bashrc .zshrc .tmux.conf; do
    if [[ -f "$repo_dir/$file" ]]; then
        if [[ -e "$HOME/$file" || -L "$HOME/$file" ]]; then
            cp -a -- "$HOME/$file" "$backup_dir/"
        fi
        cp -f -- "$repo_dir/$file" "$HOME/"
    fi
done

unit_dir="$HOME/.config/systemd/user"
mkdir -p "$unit_dir"
for source in "$repo_dir"/systemd/user/*; do
    [[ -f "$source" ]] || continue
    name="${source##*/}"
    target="$unit_dir/$name"
    if [[ -e "$target" ]] && ! cmp -s -- "$source" "$target"; then
        cp -a -- "$target" "$backup_dir/$name"
    fi
    cp -f -- "$source" "$target"
done

if command -v systemctl >/dev/null 2>&1 && [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
    systemctl --user daemon-reload
fi

echo "Configuration files installed. Existing files were backed up to: $backup_dir"
