#!/usr/bin/env python3
import json
import subprocess
import sys

def send_async_notify(title, msg):
    try:
        subprocess.Popen(["notify-send", title, msg], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def trigger_waybar_refresh():
    try:
        # SIGRTMIN is 34 on x86_64, 34 + 8 = 42
        subprocess.run(["pkill", "-42", "waybar"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def is_daemon_active():
    res = subprocess.run(["systemctl", "is-active", "warp-svc"], capture_output=True, text=True)
    return res.stdout.strip() == "active"

def ensure_daemon():
    if not is_daemon_active():
        subprocess.run(["sudo", "systemctl", "start", "warp-svc"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def get_warp_raw_status():
    if not is_daemon_active():
        return "Daemon Stopped"
    res = subprocess.run(["warp-cli", "status"], capture_output=True, text=True)
    out = res.stdout.strip()
    if "Status update: Connected" in out:
        return "Connected"
    elif "Status update: Connecting" in out:
        return "Connecting"
    elif "Status update: Disconnected" in out:
        return "Disconnected"
    return out.splitlines()[0] if out else "Unknown"

def get_waybar_status():
    raw = get_warp_raw_status()
    if raw == "Connected":
        return json.dumps({
            "text": "  ON",
            "alt": "enabled",
            "tooltip": "Cloudflare WARP: Connected\nClick to disconnect",
            "class": "enabled"
        })
    elif raw == "Connecting":
        return json.dumps({
            "text": "  ...",
            "alt": "connecting",
            "tooltip": "Cloudflare WARP: Connecting...",
            "class": "connecting"
        })
    elif raw == "Daemon Stopped":
        return json.dumps({
            "text": "  OFF",
            "alt": "disabled",
            "tooltip": "WARP Daemon stopped\nClick to start daemon and connect",
            "class": "disabled"
        })
    else:
        return json.dumps({
            "text": "  OFF",
            "alt": "disabled",
            "tooltip": "Cloudflare WARP: Disconnected\nClick to connect",
            "class": "disabled"
        })

def toggle_connection():
    ensure_daemon()
    raw = get_warp_raw_status()
    if raw == "Connected":
        subprocess.run(["warp-cli", "disconnect"], capture_output=True, text=True)
        send_async_notify("WARP", "WARP Disconnected")
    else:
        subprocess.run(["warp-cli", "connect"], capture_output=True, text=True)
        send_async_notify("WARP", "WARP Connecting...")
    trigger_waybar_refresh()

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] in ("toggle", "menu"):
        toggle_connection()
    else:
        print(get_waybar_status())
