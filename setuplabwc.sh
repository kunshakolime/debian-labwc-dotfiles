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
# VPS-only:  xwayland, wayvnc, novnc, websockify, openssl
# Desktop-only: wlsunset, ntfs-3g, bluez/libspa-0.2-bluetooth, brightnessctl,
#               network-manager, wlr-randr
install_packages() {
    local pkgs=(
        labwc waybar wofi foot fonts-font-awesome swaybg
        dunst libnotify-bin copyq wl-clipboard grim slurp
        jq curl btop nnn vim tmux fastfetch numix-gtk-theme
        pipewire pipewire-pulse wireplumber pamixer pulsemixer playerctl
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr lxpolkit
        vlc imv firefox-esr
    )

    if [ "$MODE" = "desktop" ]; then
        pkgs+=( wlsunset ntfs-3g libspa-0.2-bluetooth bluez brightnessctl network-manager wlr-randr )
    else
        pkgs+=( xwayland wayvnc novnc websockify openssl )
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
        cp "$SCRIPT_DIR/.local/bin/power"      "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/volume" "$HOME/.local/bin/kb-layout" "$HOME/.local/bin/resolution" "$HOME/.local/bin/power"
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

    # --- VPS configs: autostart (VNC+audio), rc.xml (no brightness), waybar (no bluetooth/battery) ---
    cp -r "$SCRIPT_DIR/vps/.config/"* "$HOME/.config/"
    chmod +x "$HOME/.config/labwc/autostart"
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
