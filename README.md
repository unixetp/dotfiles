# Arch Linux dotfiles

```bash
git clone https://github.com/unixetp/dotfiles.git
cd dotfiles
./install.sh
```

The installer checks what is missing and asks before installing. It uses `pacman -Syu` (a full system upgrade) for Arch packages and builds AUR packages locally. It asks for your sudo password only when required. Existing config files are backed up to `~/.config-backups/`.

Add your wallpapers to `~/Pictures/Wallpapers`. If this is a new WARP install, register it with Cloudflare after setup.

An AI combined the repo and all the dotfiles into one repo cuz im lazy.
(i think about rewriting it in quickshell or smth)
