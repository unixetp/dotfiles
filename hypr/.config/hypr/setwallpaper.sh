#!/bin/bash

STATE_FILE="$HOME/.config/hypr/wallpaper"

wallpaper="$1"

if [[ -z "$wallpaper" ]]; then
    if [[ -f "$STATE_FILE" ]] && [[ -f "$(cat "$STATE_FILE")" ]]; then
        wallpaper="$(cat "$STATE_FILE")"
    else
        wallpaper="$HOME/Pictures/Wallpapers/catpuccin.jpg"
    fi
fi

if [[ ! -f "$wallpaper" ]]; then
    echo "Usage: $0 <path-to-wallpaper>" >&2
    exit 1
fi

mkdir -p "$(dirname "$STATE_FILE")"
printf '%s\n' "$wallpaper" > "$STATE_FILE"

pkill swaybg
setsid -f swaybg -i "$wallpaper" -m fill

scheme_args=""
if python3 -W ignore::DeprecationWarning - "$wallpaper" <<'EOF'
import sys
from PIL import Image

im = Image.open(sys.argv[1]).convert("RGB")
im.thumbnail((160, 160))

total_sat = 0.0
n = 0
for r, g, b in im.getdata():
    mx = max(r, g, b)
    mn = min(r, g, b)
    total_sat += 0.0 if mx == 0 else (mx - mn) / mx
    n += 1

sys.exit(0 if (total_sat / n) < 0.12 else 1)
EOF
then
    scheme_args="-t scheme-monochrome"
fi

matugen image --source-color-index 0 $scheme_args "$wallpaper"

python3 -W ignore::DeprecationWarning - <<'EOF'
import os
import re

def css_var(path, name):
    try:
        with open(path) as f:
            m = re.search(r"@define-color\s+" + name + r"\s+(#[0-9a-fA-F]{6})", f.read())
        return m.group(1) if m else None
    except Exception:
        return None

def to_rgba(hex6):
    h = hex6.lstrip("#")
    return f"rgba({h}ff)"

theme = os.path.expanduser("~/.config/waybar/current_theme.css")
active = css_var(theme, "foreground-dark") or "#888888"
inactive = css_var(theme, "overlay") or "#333333"

with open(os.path.expanduser("~/.config/hypr/colors.conf"), "w") as f:
    f.write(f"$active_border = {to_rgba(active)}\n")
    f.write(f"$inactive_border = {to_rgba(inactive)}\n")
EOF

hyprctl reload >/dev/null 2>&1 || true

python3 -W ignore::DeprecationWarning - <<'EOF'
import os
import re

def parse(hex6):
    return [int(hex6[i:i+2], 16) for i in (1, 3, 5)]

def to_hex(rgb):
    return f"#{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}"

def lum(rgb):
    r, g, b = rgb
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0

def brighten(rgb, target):
    mx = max(rgb)
    if mx == 0:
        return [target, target, target]
    s = target / mx
    return [min(255, int(c * s)) for c in rgb]

kitty = os.path.expanduser("~/.config/kitty/colors.conf")
with open(kitty) as f:
    lines = f.readlines()

out = []
for line in lines:
    m = re.match(r"^(color\d+)\s+(#[0-9a-fA-F]{6})", line)
    if not m:
        out.append(line)
        continue
    name, hex6 = m.group(1), m.group(2)
    idx = int(name[5:])
    rgb = parse(hex6)
    if idx == 0 or idx == 8:
        out.append(line)
        continue
    if idx == 7 or idx == 15:
        rgb = brighten(rgb, 225) if lum(rgb) < 0.55 else rgb
    elif lum(rgb) < 0.35:
        rgb = brighten(rgb, 185)
    out.append(line.replace(hex6, to_hex(rgb), 1))

with open(kitty, "w") as f:
    f.writelines(out)

m = re.search(r"^foreground\s+(#[0-9a-fA-F]{6})", "".join(out), re.M)
if m and lum(parse(m.group(1))) < 0.5:
    lines2 = "".join(out)
    lines2 = re.sub(
        r"^(foreground\s+)#[0-9a-fA-F]{6}",
        lambda mm: mm.group(1) + to_hex(brighten(parse(m.group(1)), 220)),
        lines2,
        flags=re.M,
    )
    with open(kitty, "w") as f:
        f.write(lines2)
EOF

killall -SIGUSR1 kitty 2>/dev/null || true
