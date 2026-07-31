#!/bin/bash
# Uninstall VPS-specific stuff: VNC processes, wayvnc config,
# headless env vars, VNC password.
# Does NOT remove any packages or shared configs.

echo "Stopping VPS services..."

# --- Kill running processes ---
pkill -f "wayvnc" 2>/dev/null || true
pkill -f "websockify" 2>/dev/null || true

# --- Remove wayvnc config and VNC password ---
rm -rf "$HOME/.config/wayvnc"
rm -rf "$HOME/.vnc"

# --- Remove headless env vars from labwc environment ---
ENV_FILE="$HOME/.config/labwc/environment"
if [ -f "$ENV_FILE" ]; then
    sed -i '/^WLR_BACKENDS=headless$/d' "$ENV_FILE"
    sed -i '/^WLR_LIBINPUT_NO_DEVICES=1$/d' "$ENV_FILE"
    sed -i '/^WLR_HEADLESS_WIDTH=/d' "$ENV_FILE"
    sed -i '/^WLR_HEADLESS_HEIGHT=/d' "$ENV_FILE"
fi

# --- Restore default autostart (no VNC) ---
cat > "$HOME/.config/labwc/autostart" <<'AUTOSTART'
#!/bin/bash

# === What runs when labwc starts ===

foot --server &
swaybg --image "$HOME/Pictures/Wallpapers/debian-dark-wallpaper.png" --mode fill &
waybar &
dunst &
copyq --start-server &
AUTOSTART
chmod +x "$HOME/.config/labwc/autostart"

echo ""
echo "VPS setup removed."
echo "  - wayvnc + websockify: killed"
echo "  - wayvnc config + VNC password: deleted"
echo "  - headless env vars: removed from labwc environment"
echo "  - autostart: restored to default (no VNC)"
echo ""
echo "Packages were NOT removed. Reboot or run 'labwc' to apply."
