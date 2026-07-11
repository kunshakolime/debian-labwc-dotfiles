#!/bin/bash
# Uninstall VPS-specific stuff: VNC services, noVNC proxy, PulseAudio TCP,
# wayvnc config, and VNC password.
# Does NOT remove any packages.

echo "Removing VPS services and autostart entries..."

# --- Stop and disable systemd system services ---
for svc in wayvnc.service novnc.service; do
    systemctl stop "$svc" 2>/dev/null || true
    systemctl disable "$svc" 2>/dev/null || true
    rm -f "/etc/systemd/system/$svc"
done

# --- Remove wayvnc config and VNC password ---
rm -rf "$HOME/.config/wayvnc"
rm -rf "$HOME/.vnc"

# --- Unload PulseAudio TCP module (if PulseAudio is running) ---
if command -v pactl &>/dev/null && pactl info &>/dev/null 2>&1; then
    pactl unload-module module-native-protocol-tcp 2>/dev/null || true
fi

# --- Restore default autostart (no VNC, no PulseAudio TCP) ---
cat > "$HOME/.config/labwc/autostart" <<'AUTOSTART'
#!/bin/bash

# === What runs when labwc starts ===

foot --server &
swaybg --image "$HOME/Pictures/Wallpapers/debian-dark-wallpaper.png" --mode fill &
waybar &
dunst &
wlsunset -l 52.5 -L 13.4 &
copyq --start-server &
AUTOSTART
chmod +x "$HOME/.config/labwc/autostart"

# --- Reload systemd ---
systemctl daemon-reload

echo ""
echo "VPS setup removed."
echo "  - wayvnc + noVNC services: stopped, disabled, files deleted"
echo "  - wayvnc config + VNC password: deleted"
echo "  - PulseAudio TCP module: unloaded"
echo "  - autostart: restored to default (no VNC)"
echo ""
echo "Packages were NOT removed. Reboot or run 'labwc' to apply."
