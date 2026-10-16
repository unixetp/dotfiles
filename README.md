# Arch Linux dotfiles

```bash
git clone https://github.com/unixetp/dotfiles.git
cd dotfiles
./install.sh
```

The installer installs the packages used by the included Hyprland setup, including the Bibata cursor theme from the AUR. It uses `pacman -Syu`, which performs a full system upgrade. Existing config files are backed up under `~/.config-backup-*` before being replaced. Log out and back in after installation to load the Hyprland config and start Waybar.

Add your wallpapers to `~/Pictures/Wallpapers`. If this is a new WARP install, register it with Cloudflare after setup.

The installer copies the bundled wallpapers into `~/Pictures/Wallpapers` without overwriting files already there. The Catppuccin wallpaper is used on first launch.

The installer enables a user systemd timer that checks GitHub every six hours and applies new dotfiles commits. Hyprland also checks on startup and sends a desktop notification with the result. New configs are applied immediately when the graphical session is available. This does not update system packages. Updates are skipped if the local repository has uncommitted changes or is not on `main`; replaced config files are backed up under `~/.config-backup-*`.

To enable updates on an existing installation, run `./sync-configs.sh` and then `systemctl --user enable --now dotfiles-update.timer` from the repository directory.

An AI combined the repo and all the dotfiles into one repo cuz im lazy.
(i think about rewriting it in quickshell or smth)
