#!/bin/bash
set -e

# labwc desktop / VPS setup — safe to run multiple times (skips what's done).
#
#   Desktop:  ./setuplabwc.sh
#   VPS:      ./setuplabwc.sh --vps <vnc-password>
#
# VPS mode adds noVNC (browser VNC), sound forwarding and screenshots, and
# drops hardware-dependent pieces (brightness, bluetooth, blue light filter).

MODE="desktop"
VNC_PASSWORD=""

case "$1" in
    --vps)
        MODE="vps"
        VNC_PASSWORD="${2:-}"
        ;;
    "")
        ;;
    *)
        echo "Usage: $0 [--vps <vnc-password>]"
        exit 1
        ;;
esac

if [ "$MODE" = "vps" ] && [ -z "$VNC_PASSWORD" ]; then
    echo "Usage: $0 --vps <vnc-password>"
    echo "  The password protects access to the noVNC web interface."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ===== Packages =====
# VPS-only:  xwayland, wayvnc, novnc, websockify, xdg-desktop-portal-wlr, openssl
# Desktop-only: wlsunset, ntfs-3g, bluez/libspa-0.2-bluetooth, brightnessctl,
#               network-manager, wlr-randr
install_packages() {
    local pkgs=(
        labwc waybar wofi foot fonts-font-awesome swaybg
        dunst libnotify-bin copyq wl-clipboard grim slurp
        jq curl btop nnn vim tmux fastfetch numix-gtk-theme
        pipewire pipewire-pulse wireplumber pamixer pulsemixer playerctl
        xdg-desktop-portal xdg-desktop-portal-gtk
        vlc imv firefox-esr
    )

    if [ "$MODE" = "desktop" ]; then
        pkgs+=( wlsunset ntfs-3g libspa-0.2-bluetooth bluez brightnessctl network-manager wlr-randr )
    else
        pkgs+=( xwayland wayvnc novnc websockify xdg-desktop-portal-wlr openssl )
    fi

    sudo apt install -y "${pkgs[@]}"
}

# JetBrainsMono Nerd Font — waybar configs use Nerd Font icons (CPU, memory, etc.)
install_nerd_font() {
    local font_dir="$HOME/.local/share/fonts"
    if fc-list | grep -qi "JetBrainsMono.*Nerd" 2>/dev/null; then
        echo "JetBrainsMono Nerd Font already installed, skipping."
        return
    fi
    mkdir -p "$font_dir"
    local nerd_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    echo "Downloading JetBrainsMono Nerd Font (icons for waybar)..."
    curl -L "$nerd_url" -o /tmp/JetBrainsMono.tar.xz
    tar -xf /tmp/JetBrainsMono.tar.xz -C "$font_dir"
    fc-cache -fv
    echo "Fonts installed."
}

apply_configs() {
    echo "Applying configs..."
    mkdir -p "$HOME/.config"
    cp -r "$SCRIPT_DIR/.config/labwc"   "$HOME/.config/"
    cp -r "$SCRIPT_DIR/.config/waybar"  "$HOME/.config/"
    chmod +x "$HOME/.config/waybar/stats.sh" "$HOME/.config/waybar/netspeed.sh"
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

    if [ "$MODE" = "desktop" ]; then
        cp "$SCRIPT_DIR/.local/bin/"* "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/kb-layout" "$HOME/.local/bin/brightness" \
                 "$HOME/.local/bin/volume"    "$HOME/.local/bin/resolution" \
                 "$HOME/.local/bin/nightlight"
    else
        cp "$SCRIPT_DIR/.local/bin/volume"     "$HOME/.local/bin/"
        cp "$SCRIPT_DIR/.local/bin/kb-layout"  "$HOME/.local/bin/"
        cp "$SCRIPT_DIR/.local/bin/resolution" "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/volume" "$HOME/.local/bin/kb-layout" "$HOME/.local/bin/resolution"
    fi
}

install_bluetui() {
    local url="https://github.com/pythops/bluetui/releases/download/v0.8.1/bluetui-x86_64-linux-musl"
    local bin="/usr/local/bin/bluetui"
    if [ -f "$bin" ]; then
        echo "bluetui already installed, skipping."
        return
    fi
    echo "Downloading bluetui..."
    sudo curl -L "$url" -o "$bin"
    sudo chmod +x "$bin"
    echo "bluetui installed."
}

setup_path_and_nnn() {
    case ":$PATH:" in
        *:"$HOME/.local/bin":*) ;;
        *) echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" ;;
    esac

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
}

# ===== VPS-specific overrides (no display hardware) =====
configure_vps() {
    echo "Configuring headless VNC setup..."

    # Headless environment
    cat >> "$HOME/.config/labwc/environment" <<'EOF'
WLR_BACKENDS=headless
WLR_LIBINPUT_NO_DEVICES=1
XCURSOR_SIZE=24
EOF

    # VNC password. Distro wayvnc (no auth reordering patch): noVNC shows a
    # username+password prompt — log in with username "user" and the password set below.
    mkdir -p "$HOME/.vnc" "$HOME/.config/wayvnc"
    cat > "$HOME/.config/wayvnc/config" <<EOF
address=0.0.0.0
port=5900
enable_auth=true
relax_encryption=true
username=user
password=$VNC_PASSWORD
EOF
    chmod 600 "$HOME/.config/wayvnc/config"

    # --- labwc autostart: audio forwarding, no wlsunset, wayvnc + noVNC ---
    cat > "$HOME/.config/labwc/autostart" <<'AUTOSTART'
#!/bin/bash

# === What runs when labwc starts ===

foot --server &
swaybg --image "$HOME/Pictures/Wallpapers/debian-dark-wallpaper.png" --mode fill &
waybar &
dunst &
copyq --start-server &

# VNC: wayvnc then noVNC websockify bridges (HTTPS + HTTP)
# Only start if not already running, so a labwc restart can't double-bind
# the ports (avoids "Address already in use").
if ! pgrep -x wayvnc > /dev/null 2>&1; then
  wayvnc 0.0.0.0 5900 &
fi
sleep 1
# Self-signed cert for the HTTPS endpoint (browser shows a one-time warning).
# Replace with a real cert if you put this behind an HTTPS reverse proxy.
CERT_DIR="$HOME/.config/wayvnc"
if [ ! -f "$CERT_DIR/cert.pem" ]; then
  openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
    -keyout "$CERT_DIR/key.pem" -out "$CERT_DIR/cert.pem" \
    -subj "/CN=noVNC" >/dev/null 2>&1
fi
# HTTPS: works in any browser (WebCrypto needs a secure context).
if ! pgrep -f "websockify.*6080" > /dev/null 2>&1; then
  websockify --cert "$CERT_DIR/cert.pem" --key "$CERT_DIR/key.pem" \
    --web /usr/share/novnc 6080 localhost:5900 &
fi
# Plain HTTP: for localhost or as the backend for an HTTPS reverse proxy.
if ! pgrep -f "websockify.*6081" > /dev/null 2>&1; then
  websockify --web /usr/share/novnc 6081 localhost:5900 &
fi

# Audio: PipeWire stack (systemd user units are skipped as root via
# ConditionUser=!root, so start the daemons directly).
if ! pgrep -x pipewire > /dev/null 2>&1; then
  pipewire &
fi
if ! pgrep -x wireplumber > /dev/null 2>&1; then
  wireplumber &
fi
if ! pgrep -x pipewire-pulse > /dev/null 2>&1; then
  pipewire-pulse &
fi
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
}

finish() {
    echo ""
    if [ "$MODE" = "vps" ]; then
        echo "===== VPS/Container setup complete ====="
        echo ""
        echo "VNC password set."
        echo "noVNC (HTTPS - works in any browser): https://<your-vps-ip>:6080/vnc.html"
        echo "  login with username 'user' and the password you set (accept the self-signed cert warning)"
        echo "noVNC (HTTP - localhost or HTTPS reverse-proxy backend): http://<your-vps-ip>:6081/vnc.html"
        echo "VNC client: connect to <your-vps-ip>:5900 (username: user) with the password you set"
        echo "Audio: PipeWire stack starts with labwc (pulsemixer widget works)"
    else
        echo "===== Setup complete ====="
    fi
    echo ""
    echo "Reboot or run 'labwc' from tty1 to start your new desktop."
    echo "Press Super+Space to launch apps (wofi)."
}

install_packages
install_nerd_font
apply_configs
setup_path_and_nnn

if [ "$MODE" = "desktop" ]; then
    install_bluetui
else
    configure_vps
fi

finish
