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

# Friendly banner: say who we're setting up and where configs land, so a root
# run (configs go to /root) never gets confused with a normal-user run.
show_target() {
    local target="$USER"
    [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ] && target="$SUDO_USER"
    echo "======================================"
    echo " labwc setup — mode: $MODE"
    echo " target user: $target (home: $HOME)"
    if [ "$EUID" -eq 0 ]; then
        echo " running as root — configs go to /root."
        echo " to set up a normal user instead, run this as that user (no sudo)."
    else
        echo " packages install via sudo; configs go to $HOME."
    fi
    echo "======================================"
}

# brightnessctl needs write access to the backlight device, granted to the
# 'video' group. Root already has it; normal users need to be added.
ensure_video_group() {
    if [ "$EUID" -ne 0 ] && ! id -nG "$USER" | tr ' ' '\n' | grep -qx video; then
        echo "Adding $USER to the 'video' group (needed for brightness keys)..."
        sudo usermod -aG video "$USER"
        echo "  Done — log out and back in for it to take effect."
    fi
}

# ===== Packages =====
# VPS-only:  xwayland, wayvnc, novnc, websockify, openssl
# Desktop-only: wlsunset, ntfs-3g, bluez/libspa-0.2-bluetooth, brightnessctl,
#               network-manager, network-manager-gnome, wlr-randr,
#               gnome-disk-utility
# Network mounts (mount-net): davfs2 (WebDAV), cifs-utils (SMB), sshfs (SFTP)
install_packages() {
    local pkgs=(
        labwc waybar wofi foot fonts-font-awesome swaybg
        dunst libnotify-bin wl-clipboard grim slurp
        jq curl btop nnn vim tmux fastfetch
        pipewire pipewire-pulse wireplumber pamixer pulsemixer playerctl
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr lxpolkit
        vlc loupe firefox-esr swappy cliphist
        davfs2 cifs-utils sshfs
    )

    if [ "$MODE" = "desktop" ]; then
        pkgs+=( wlsunset ntfs-3g libspa-0.2-bluetooth bluez brightnessctl network-manager network-manager-gnome wlr-randr gnome-disk-utility )
    else
        pkgs+=( xwayland wayvnc novnc websockify openssl zram-tools )
    fi

    # --no-upgrade: install what's missing but never upgrade already-installed
    # packages (firefox-esr, curl, ntfs-3g, ...) during setup.
    sudo apt install --no-upgrade -y "${pkgs[@]}"
}

# JetBrainsMono Nerd Font — waybar configs use Nerd Font icons (CPU, memory, etc.)
# Bundled in vendor/fonts/ so setup never needs network access.
install_nerd_font() {
    local font_dir="$HOME/.local/share/fonts"
    local src_dir="$SCRIPT_DIR/vendor/fonts"
    if fc-list | grep -qi "JetBrainsMono.*Nerd" 2>/dev/null; then
        echo "JetBrainsMono Nerd Font already installed, skipping."
        return
    fi
    if [ ! -f "$src_dir/JetBrainsMonoNerdFont-Regular.ttf" ]; then
        echo "ERROR: fonts missing from $src_dir (clone must include vendor/). Aborting."
        exit 1
    fi
    mkdir -p "$font_dir"
    cp "$src_dir"/*.ttf "$font_dir/"
    fc-cache -f >/dev/null
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
                 "$HOME/.local/bin/nightlight" "$HOME/.local/bin/wallpaper" \
                 "$HOME/.local/bin/wallpaper-rotate" "$HOME/.local/bin/mount-net" \
                 "$HOME/.local/bin/menu" "$HOME/.local/bin/control" "$HOME/.local/bin/widgets"
        cp "$SCRIPT_DIR/.local/share/applications/desktop-only/"*.desktop "$HOME/.local/share/applications/"
    else
        cp "$SCRIPT_DIR/.local/bin/volume"     "$HOME/.local/bin/"
        cp "$SCRIPT_DIR/.local/bin/kb-layout"  "$HOME/.local/bin/"
        cp "$SCRIPT_DIR/.local/bin/resolution" "$HOME/.local/bin/"
        cp "$SCRIPT_DIR/.local/bin/power"      "$HOME/.local/bin/"
        cp "$SCRIPT_DIR/.local/bin/clipboard"  "$HOME/.local/bin/"
        cp "$SCRIPT_DIR/.local/bin/mount-net"  "$HOME/.local/bin/"
        cp "$SCRIPT_DIR/.local/bin/menu"       "$HOME/.local/bin/"
        cp "$SCRIPT_DIR/.local/bin/control"    "$HOME/.local/bin/"
        cp "$SCRIPT_DIR/.local/bin/widgets"    "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/volume" "$HOME/.local/bin/kb-layout" "$HOME/.local/bin/resolution" "$HOME/.local/bin/power" "$HOME/.local/bin/clipboard" "$HOME/.local/bin/mount-net" "$HOME/.local/bin/menu" "$HOME/.local/bin/control" "$HOME/.local/bin/widgets"
    fi
}

# Packet (Quick Share) — desktop-only, from the prebuilt .deb so setup never
# needs a compile toolchain. Skipped on VPS installs (no Bluetooth/Wi-Fi).
install_packet() {
    local url="https://github.com/kunshakolime/debian-13-tricks/raw/refs/heads/main/builds/packet/packet_0.6.1_amd64.deb"
    local deb="packet_0.6.1_amd64.deb"
    local tmp

    if command -v packet >/dev/null 2>&1; then
        echo "packet already installed, skipping."
        return
    fi

    tmp="$(mktemp -d)"
    echo "Downloading packet (Quick Share)..."
    if ! curl -fL "$url" -o "$tmp/$deb"; then
        echo "WARNING: packet download failed, skipping."
        rm -rf "$tmp"
        return
    fi
    sudo apt install --no-upgrade -y "$tmp/$deb"
    rm -rf "$tmp"
}

install_bluetui() {
    local bin="/usr/local/bin/bluetui"
    if [ -f "$bin" ]; then
        echo "bluetui already installed, skipping."
        return
    fi
    if [ ! -f "$SCRIPT_DIR/vendor/bluetui" ]; then
        echo "WARNING: vendor/bluetui not found, skipping bluetui install."
        return
    fi
    echo "Installing bluetui from repo..."
    sudo cp "$SCRIPT_DIR/vendor/bluetui" "$bin"
    sudo chmod +x "$bin"
    echo "bluetui installed."
}

# libadwaita apps (GNOME Disks, Loupe, ...) read the GSettings color-scheme
# first; ~/.config/gtk-4.0/settings.ini is only a fallback. Set both.
configure_dark_theme() {
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
    fi
}

setup_path_and_nnn() {
    local line='export PATH="$HOME/.local/bin:$PATH"'
    # dedupe: drop any existing copies of the line, then append exactly one
    if [ -f "$HOME/.bashrc" ] && grep -qF "$line" "$HOME/.bashrc"; then
        grep -vxF "$line" "$HOME/.bashrc" > "$HOME/.bashrc.tmp"
        mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"
    fi
    echo "$line" >> "$HOME/.bashrc"

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

    # zram — compressed swap in RAM, 50% of installed memory. PERCENT scales
    # with the box (512 MiB on 1 GiB, 4 GiB on 8 GiB), so one config fits all.
    # Higher PRIORITY means zram is used before any disk swap.
    cat | sudo tee /etc/default/zramswap >/dev/null <<'EOF'
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF
    sudo systemctl enable --now zramswap

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

    # --- VPS configs: autostart (VNC+audio), waybar (no bluetooth/battery) ---
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
    echo "Network drives (WebDAV/SMB/SFTP): run 'mount-net add' once per share."
}

# SETUP_TEST=1 loads the functions only (no side effects) so they can be tested.
if [ "${SETUP_TEST:-0}" != "1" ]; then
    show_target
    install_packages
    install_nerd_font
    apply_configs
    configure_dark_theme
    setup_path_and_nnn

    if [ "$MODE" = "desktop" ]; then
        install_bluetui
        install_packet
        ensure_video_group
    else
        configure_vps
    fi

    finish
fi
