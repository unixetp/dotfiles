# Arch Linux dotfiles

```bash
git clone https://github.com/unixetp/dotfiles.git
cd dotfiles
./install.sh
```

The installer installs the packages used by the included Hyprland setup, including the Bibata cursor theme from the AUR. It uses `pacman -Syu`, which performs a full system upgrade. Existing config files are backed up under `~/.config-backup-*` before being replaced. Log out and back in after installation to load the Hyprland config and start Waybar.

Add your wallpapers to `~/Pictures/Wallpapers`. If this is a new WARP install, register it with Cloudflare after setup.

An AI combined the repo and all the dotfiles into one repo cuz im lazy.
(i think about rewriting it in quickshell or smth)
