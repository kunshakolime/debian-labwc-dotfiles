#!/bin/bash
set -e

# VPS / Container variant of the labwc setup.
# Includes: noVNC (browser VNC), sound forwarding, screenshots.
# Strips only: brightness, bluetooth, blue light filter (no hardware).
#
# Usage: ./setuplabwc-vps.sh <vnc-password>

VNC_PASSWORD="${1:-}"

if [ -z "$VNC_PASSWORD" ]; then
    echo "Usage: $0 <vnc-password>"
    echo "  The password protects access to the noVNC web interface."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ===== Packages =====
# Added vs main setup:
#   wayvnc        - VNC server for wlroots Wayland compositors
#   novnc          - browser-based VNC client
#   websockify     - WebSocket-to-TCP proxy (bridges noVNC to wayvnc)
#   xwayland       - X11 compat layer (needed by some apps via VNC)
#
# Removed vs main setup (no hardware):
#   brightnessctl                  - no screen backlight
#   wlsunset                       - no blue light filter
#   bluez/libspa-0.2-bluetooth     - no bluetooth
#   network-manager                - use systemd-networkd/netplan
#   wlr-randr                     - no display hardware

sudo apt install -y \
  labwc \
  xwayland \
  waybar \
  wofi \
  foot \
  fonts-font-awesome \
  swaybg \
  dunst \
  libnotify-bin \
  copyq \
  wl-clipboard \
  grim \
  slurp \
  jq \
  curl \
  btop \
  nnn \
  vim \
  tmux \
  fastfetch \
  numix-gtk-theme \
  pipewire \
  pipewire-pulse \
  wireplumber \
  pamixer \
  pulsemixer \
  playerctl \
  wayvnc \
  novnc \
  websockify \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  xdg-desktop-portal-wlr \
  vlc \
  imv \
  firefox-esr

# JetBrainsMono Nerd Font
FONT_DIR="$HOME/.local/share/fonts"
if fc-list | grep -qi "JetBrainsMono.*Nerd" 2>/dev/null; then
    echo "JetBrainsMono Nerd Font already installed, skipping."
else
    mkdir -p "$FONT_DIR"
    NERD_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    echo "Downloading JetBrainsMono Nerd Font..."
    curl -L "$NERD_URL" -o /tmp/JetBrainsMono.tar.xz
    tar -xf /tmp/JetBrainsMono.tar.xz -C "$FONT_DIR"
    fc-cache -fv
    echo "Fonts installed."
fi

# ===== Apply configs =====
echo "Applying configs..."

# Copy base configs (same as main setup)
cp -r "$SCRIPT_DIR/.config/labwc"   "$HOME/.config/"
cp -r "$SCRIPT_DIR/.config/waybar"  "$HOME/.config/"
chmod +x "$HOME/.config/waybar/stats.sh"
chmod +x "$HOME/.config/waybar/netspeed.sh"
cp -r "$SCRIPT_DIR/.config/wofi"    "$HOME/.config/"
cp -r "$SCRIPT_DIR/.config/foot"    "$HOME/.config/"
cp -r "$SCRIPT_DIR/.config/dunst"   "$HOME/.config/"
cp -r "$SCRIPT_DIR/.config/gtk-3.0" "$HOME/.config/"
cp -r "$SCRIPT_DIR/.config/gtk-4.0" "$HOME/.config/"
cp "$SCRIPT_DIR/.config/mimeapps.list" "$HOME/.config/"
mkdir -p "$HOME/.local/share/applications"
cp "$SCRIPT_DIR/.local/share/applications/"*.desktop "$HOME/.local/share/applications/"
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/.local/bin"
cp "$SCRIPT_DIR/Pictures/Wallpapers/"* "$HOME/Pictures/Wallpapers/"

# Copy scripts: volume (for sound), kb-layout, resolution
cp "$SCRIPT_DIR/.local/bin/volume"     "$HOME/.local/bin/"
cp "$SCRIPT_DIR/.local/bin/kb-layout"  "$HOME/.local/bin/"
cp "$SCRIPT_DIR/.local/bin/resolution" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/volume" "$HOME/.local/bin/kb-layout" "$HOME/.local/bin/resolution"

# ===== VNC password =====
mkdir -p "$HOME/.vnc" "$HOME/.config/wayvnc"
echo "$VNC_PASSWORD" > "$HOME/.vnc/passwd"
chmod 600 "$HOME/.vnc/passwd"
cat > "$HOME/.config/wayvnc/config" <<EOF
password-file=$HOME/.vnc/passwd
EOF

# ===== systemd services: wayvnc + noVNC (always-on system services) =====
cp "$SCRIPT_DIR/services/wayvnc.service" /etc/systemd/system/
cp "$SCRIPT_DIR/services/novnc.service"  /etc/systemd/system/
systemctl daemon-reload
systemctl enable wayvnc.service novnc.service
echo "VNC services enabled (will start on boot)."

# ===== Server-specific overrides =====

# --- labwc autostart: audio forwarding, no wlsunset ---
cat > "$HOME/.config/labwc/autostart" <<'AUTOSTART'
#!/bin/bash

# === What runs when labwc starts ===

foot --server &
swaybg --image "$HOME/Pictures/Wallpapers/debian-dark-wallpaper.png" --mode fill &
waybar &
dunst &
copyq --start-server &

# Audio: start PulseAudio with TCP forwarding (for VNC client audio)
pulseaudio --start \
  --load="module-native-protocol-tcp auth-anonymous=1" \
  2>/dev/null &
AUTOSTART
chmod +x "$HOME/.config/labwc/autostart"

# --- labwc rc.xml: keep volume/screenshots/media, remove brightness only ---
cat > "$HOME/.config/labwc/rc.xml" <<'RCXML'
<?xml version="1.0" encoding="UTF-8"?>
<labwc_config>
  <core>
    <gap>6</gap>
  </core>

  <keyboard>
    <default />

    <!-- Launcher -->
    <keybind key="W-Space">
      <action name="Execute" command="wofi --show drun" />
    </keybind>

    <!-- Terminal -->
    <keybind key="W-Return">
      <action name="Execute" command="footclient" />
    </keybind>

    <!-- Close window -->
    <keybind key="W-q">
      <action name="Close" />
    </keybind>

    <!-- Window cycling -->
    <keybind key="W-Tab">
      <action name="NextWindow" />
    </keybind>
    <keybind key="W-S-Tab">
      <action name="PreviousWindow" />
    </keybind>

    <!-- Screenshots -->
    <keybind key="W-Print">
      <action name="Execute" command="grim" />
    </keybind>
    <keybind key="W-S-Print">
      <action name="Execute" command='grim -g \"$(slurp)\"' />
    </keybind>

    <!-- Volume control -->
    <keybind key="W-Up">
      <action name="Execute" command="volume up" />
    </keybind>
    <keybind key="W-Down">
      <action name="Execute" command="volume down" />
    </keybind>
    <keybind key="W-m">
      <action name="Execute" command="volume mute" />
    </keybind>
    <keybind key="XF86AudioRaiseVolume">
      <action name="Execute" command="volume up" />
    </keybind>
    <keybind key="XF86AudioLowerVolume">
      <action name="Execute" command="volume down" />
    </keybind>
    <keybind key="XF86AudioMute">
      <action name="Execute" command="volume mute" />
    </keybind>

    <!-- Media controls -->
    <keybind key="XF86AudioPlay">
      <action name="Execute" command="playerctl play-pause" />
    </keybind>
    <keybind key="XF86AudioNext">
      <action name="Execute" command="playerctl next" />
    </keybind>
    <keybind key="XF86AudioPrev">
      <action name="Execute" command="playerctl previous" />
    </keybind>
  </keyboard>

  <windowSnapMaxRange>10</windowSnapMaxRange>

  <theme>
    <name>Numix</name>
    <cornerRadius>6</cornerRadius>
  </theme>
</labwc_config>
RCXML

# --- waybar config: keep pulseaudio, remove bluetooth/battery/nightlight ---
cat > "$HOME/.config/waybar/config.jsonc" <<'WAYBAR'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "margin-top": 6,
    "margin-bottom": 0,
    "margin-left": 6,
    "margin-right": 6,
    "spacing": 8,

    "modules-left": ["wlr/taskbar"],
    "modules-center": ["clock"],
    "modules-right": ["custom/netspeed", "custom/stats", "network", "pulseaudio", "tray", "custom/weather"],

    "wlr/taskbar": {
        "format": "{name}",
        "icon": true,
        "icon-theme": "Adwaita",
        "all-outputs": false,
        "on-click": "activate",
        "on-click-middle": "close"
    },

    "clock": {
        "format": "{:%a %b %d  %H:%M}",
        "tooltip-format": "{:%A, %B %d %Y  %I:%M %p}",
        "interval": 60
    },

    "custom/stats": {
        "exec": "$HOME/.config/waybar/stats.sh",
        "interval": 3,
        "on-click": "footclient -e btop"
    },

    "custom/netspeed": {
        "exec": "$HOME/.config/waybar/netspeed.sh",
        "interval": 3,
        "on-click": "footclient -e btop"
    },

    "network": {
        "format-ethernet": "  Connected",
        "format-disconnected": "  Disconnected",
        "tooltip-format-ethernet": "IP: {ipaddr}",
        "interval": 30
    },

    "pulseaudio": {
        "format": "{icon}  {volume}%",
        "format-muted": "  Muted",
        "format-icons": {
            "default": ["", ""]
        },
        "scroll-step": 5,
        "on-click": "footclient -e pulsemixer",
        "tooltip": false
    },

    "tray": {
        "icon-size": 18,
        "spacing": 6
    },

    "custom/weather": {
        "format": "{}",
        "exec": "curl -s 'wttr.in?format=1' 2>/dev/null || echo ''",
        "interval": 1800,
        "tooltip": true,
        "tooltip-format": "Weather",
        "exec-if": "ping -c 1 -W 1 wttr.in >/dev/null 2>&1"
    }
}
WAYBAR

# --- waybar style: keep pulseaudio, remove bluetooth/battery/nightlight ---
cat > "$HOME/.config/waybar/style.css" <<'WAYBAR_CSS'
* {
    border: none;
    border-radius: 6px;
    font-family: "JetBrainsMono Nerd Font", "FontAwesome", "Fira Code", monospace;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: rgba(30, 30, 30, 0.85);
    color: #e0e0e0;
    border: 1px solid rgba(255, 255, 255, 0.08);
}

#workspaces,
#clock,
#custom-stats,
#custom-netspeed,
#network,
#pulseaudio,
#tray,
#custom-weather {
    padding: 0 10px;
    margin: 4px 2px;
    background: rgba(0, 0, 0, 0.2);
    border-radius: 6px;
}

#taskbar button {
    padding: 0 8px;
    background: transparent;
    color: #888;
    border-radius: 4px;
}

#taskbar button.active {
    color: #fff;
    background: rgba(255, 255, 255, 0.1);
}

#taskbar button:hover {
    background: rgba(255, 255, 255, 0.15);
}

#custom-stats { color: #81c784; }
#custom-netspeed { color: #4dd0e1; }
#network { color: #4dd0e1; }
#pulseaudio { color: #ffb74d; }
#clock { color: #e0e0e0; }
#custom-weather { color: #90caf9; }
WAYBAR_CSS

# ===== Ensure ~/.local/bin is in PATH =====
case ":$PATH:" in
    *:"$HOME/.local/bin":*) ;;
    *) echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" ;;
esac

# nnn quitcd wrapper
if ! grep -q "quitcd wrapper" "$HOME/.bashrc" 2>/dev/null; then
    cat >> "$HOME/.bashrc" <<'EOF'

# nnn — cd to last directory on exit (quitcd wrapper)
n() {
    [ "${NNNLVL:-0}" -eq 0 ] || { echo "nnn is already running"; return; }
    NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd" nnn "$@"
    [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
}
EOF
    echo "nnn quitcd wrapper added to ~/.bashrc"
fi

echo ""
echo "===== VPS/Container setup complete ====="
echo ""
echo "VNC password set."
echo "noVNC: open http://<your-vps-ip>:6080/vnc.html in a browser"
echo "VNC client: connect to <your-vps-ip>:5900 with the password you set"
echo "Audio: PulseAudio TCP is running — VNC client will forward sound"
echo ""
echo "Reboot or run 'labwc' from tty1 to start your desktop."
echo "Press Super+Space to launch apps (wofi)."
