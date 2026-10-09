#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo "Run this installer as your normal user, not as root." >&2
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    echo "Cannot identify the operating system; this installer supports Arch Linux only." >&2
    exit 1
fi
. /etc/os-release
if [[ "${ID:-}" != arch ]] || ! command -v pacman >/dev/null 2>&1; then
    echo "This installer supports Arch Linux only." >&2
    exit 1
fi

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
stow_packages=(hypr waybar rofi wlogout kitty foot dunst swaylock matugen)

official_packages=(
    brightnessctl
    cliphist
    dunst
    fish
    foot
    git
    gpu-screen-recorder-ui
    grim
    hyprland
    hyprlock
    hyprpicker
    hyprpolkitagent
    kitty
    libnotify
    matugen
    nautilus
    noto-fonts-emoji
    playerctl
    pipewire
    pipewire-audio
    pipewire-pulse
    polkit
    procps-ng
    psmisc
    python
    python-pillow
    rofi
    rofi-emoji
    slurp
    stow
    swaybg
    swaylock
    tesseract
    tesseract-data-eng
    tesseract-data-rus
    ttf-font-awesome
    ttf-jetbrains-mono-nerd
    waybar
    wireplumber
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    xdg-utils
    xorg-xwayland
    ydotool
)
aur_packages=(bibata-cursor-theme cloudflare-warp-bin wlogout)

missing_official=()
for package in "${official_packages[@]}"; do
    if ! pacman -Qq "$package" >/dev/null 2>&1; then
        if ! pacman -Si "$package" >/dev/null 2>&1; then
            echo "Package '$package' is not available in the enabled Arch repositories." >&2
            echo "Update your package databases and rerun this installer." >&2
            exit 1
        fi
        missing_official+=("$package")
    fi
done

missing_aur=()
for package in "${aur_packages[@]}"; do
    if ! pacman -Qq "$package" >/dev/null 2>&1; then
        missing_aur+=("$package")
    fi
done

if ((${#missing_official[@]} || ${#missing_aur[@]})); then
    echo "The following packages are missing:"
    if ((${#missing_official[@]})); then
        printf '  Official Arch repositories: %s\n' "${missing_official[*]}"
    fi
    if ((${#missing_aur[@]})); then
        printf '  AUR (built locally): %s\n' "${missing_aur[*]}"
        for package in "${missing_aur[@]}"; do
            printf '    https://aur.archlinux.org/packages/%s\n' "$package"
        done
        echo "AUR build scripts will run as your user."
    fi
    read -r -p "Install these packages and continue? [y/N] " answer
    if [[ ! "$answer" =~ ^[Yy]$ ]]; then
        echo "Cancelled. No packages were installed."
        exit 0
    fi

    if ((${#missing_official[@]} || ${#missing_aur[@]})); then
        if ! command -v sudo >/dev/null 2>&1; then
            echo "sudo is required to install system packages." >&2
            exit 1
        fi
        sudo -v
        pacman_args=(--needed)
        if ((${#missing_aur[@]})); then
            pacman_args+=(base-devel git)
        fi
        pacman_args+=("${missing_official[@]}")
        echo "Installing missing packages with pacman -Syu (full system upgrade)."
        sudo pacman -Syu "${pacman_args[@]}"
    fi

    if ((${#missing_aur[@]})); then
        aur_build_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-aur.XXXXXX")"
        trap 'rm -rf -- "$aur_build_dir"' EXIT
        for package in "${missing_aur[@]}"; do
            git clone --depth 1 "https://aur.archlinux.org/${package}.git" "$aur_build_dir/$package"
            (cd "$aur_build_dir/$package" && makepkg -si)
        done
    fi
else
    echo "All required packages are already installed."
fi

backup_dir="$HOME/.config-backups/dotfiles-$(date +%Y%m%d-%H%M%S)"
backed_up=0
for package in "${stow_packages[@]}"; do
    while IFS= read -r -d '' source_file; do
        relative_path="${source_file#"$repo_dir/$package/"}"
        target_file="$HOME/$relative_path"

        if [[ -e "$target_file" || -L "$target_file" ]]; then
            if [[ -L "$target_file" ]] && [[ "$(realpath -m -- "$target_file")" == "$(realpath -m -- "$source_file")" ]]; then
                continue
            fi

            mkdir -p "$backup_dir/$(dirname -- "$relative_path")"
            mv -- "$target_file" "$backup_dir/$relative_path"
            backed_up=1
        fi
    done < <(find "$repo_dir/$package" -type f -print0)
done

stow --dir="$repo_dir" --target="$HOME" --restow "${stow_packages[@]}"

if command -v systemctl >/dev/null 2>&1 && [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
    systemctl --user enable --now ydotool.service || echo "Could not start ydotool.service; clipboard paste shortcuts may not work." >&2
fi

if (( backed_up )); then
    echo "Existing config files were backed up to: $backup_dir"
fi
echo "Arch dotfiles installed. Log out and back in to start using them."
