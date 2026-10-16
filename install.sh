#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/unixetp/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

PACMAN_PKGS=(
    brightnessctl cliphist dunst gpu-screen-recorder-ui grim hyprland hyprlock
    hyprpicker hyprpolkitagent kitty libnotify matugen nautilus noto-fonts-emoji
    otf-font-awesome pipewire pipewire-audio pipewire-pulse playerctl python
    python-pillow rofi slurp swaybg tesseract tesseract-data-eng tesseract-data-rus
    ttf-jetbrains-mono-nerd waybar wireplumber wl-clipboard xdg-desktop-portal-hyprland
    ydotool
)

AUR_PKGS=(bibata-cursor-theme-bin)

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo "Run this installer as a normal user, not as root." >&2
    exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
    echo "This installer requires pacman and supports Arch Linux." >&2
    exit 1
fi

echo "[1/4] Updating the system and installing required Arch packages..."
sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"

echo "[2/4] Installing the configured cursor theme..."
if ! command -v yay >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm git base-devel
    yay_build_dir="$(mktemp -d "${TMPDIR:-/tmp}/yay-bin.XXXXXX")"
    trap 'rm -rf -- "$yay_build_dir"' EXIT
    git clone https://aur.archlinux.org/yay-bin.git "$yay_build_dir/yay-bin"
    (cd "$yay_build_dir/yay-bin" && makepkg -si --noconfirm)
    rm -rf -- "$yay_build_dir"
    trap - EXIT
fi
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

echo "[3/4] Installing dotfiles..."
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -e "$script_dir/.git" || -d "$script_dir/.config" || -d "$script_dir/hypr/.config" ]]; then
    repo_dir="$script_dir"
elif [[ -d "$DOTFILES_DIR/.git" ]]; then
    git -C "$DOTFILES_DIR" pull --ff-only
    repo_dir="$DOTFILES_DIR"
else
    git clone "$REPO_URL" "$DOTFILES_DIR"
    repo_dir="$DOTFILES_DIR"
fi

echo "Using dotfiles from: $repo_dir"
"$repo_dir/sync-configs.sh" "$repo_dir"

if command -v systemctl >/dev/null 2>&1 && [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
    systemctl --user enable --now ydotool.service || echo "Could not start ydotool.service; clipboard paste shortcuts may not work." >&2
    systemctl --user enable --now dotfiles-update.timer || echo "Could not enable the dotfiles update timer." >&2
fi

echo "[4/4] Installation complete."
echo "Existing files were backed up to: $BACKUP_DIR"
echo "Log out and back in to load the Hyprland config and start Waybar."
