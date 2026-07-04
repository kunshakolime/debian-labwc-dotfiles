#!/bin/bash
set -e

# This script is safe to run multiple times — it skips what's already done.

# ===== What each package does =====
# labwc        - Wayland stacking compositor (the window manager itself)
# waybar       - Status bar at the top/bottom of screen
# wofi         - App launcher (press Super+Space to open)
# foot         - Terminal emulator (lightweight, Wayland-native)
# fonts-font-awesome - Icon font used by waybar
# swaybg       - Sets a wallpaper/background image
# wlsunset     - Blue light filter at night (like f.lux)
# dunst        - Notification daemon (popups for volume/battery/etc)
# libnotify-bin - Sends notifications from command line (notify-send)
# copyq        - Clipboard manager with history
# wl-clipboard - Terminal clipboard tools (wl-copy, wl-paste)
# grim         - Screenshot tool (captures screen/output)
# slurp        - Selects a region on screen (used with grim)
# jq           - JSON processor (needed by waybar scripts)
# curl         - Web requests (needed by waybar custom scripts)
# pipewire     - Audio server (sound)
# wireplumber  - Audio session manager
# btop         - System resource monitor (terminal)
# nnn          - Terminal file manager
# vim          - Terminal text editor
# tmux         - Terminal multiplexer (multiple panes in one terminal)
# imagemagick  - Image conversion (converts wallpaper SVG to PNG for swaybg)
# pamixer      - CLI volume control (used by volume.sh keybinds)
# pulsemixer   - TUI mixer (per-app volume, output device switching)
# playerctl    - Media player controls (play/pause/next/prev)

sudo apt install -y \
  labwc \
  waybar \
  wofi \
  foot \
  fonts-font-awesome \
  swaybg \
  wlsunset \
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
  pipewire \
  pipewire-pulse \
  libspa-0.2-bluetooth \
  wireplumber \
  pamixer \
  pulsemixer \
  numix-gtk-theme \
  bluez \
  brightnessctl \
  playerctl \
  network-manager \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  vlc \
  imv \
  wlr-randr \
  firefox-esr

# JetBrainsMono Nerd Font — waybar configs use Nerd Font icons (CPU, memory, etc.)
# Font Awesome alone doesn't have all the glyphs waybar needs
FONT_DIR="$HOME/.local/share/fonts"
if fc-list | grep -qi "JetBrainsMono.*Nerd" 2>/dev/null; then
    echo "JetBrainsMono Nerd Font already installed, skipping."
else
    mkdir -p "$FONT_DIR"
    NERD_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    echo "Downloading JetBrainsMono Nerd Font (icons for waybar)..."
    curl -L "$NERD_URL" -o /tmp/JetBrainsMono.tar.xz
    tar -xf /tmp/JetBrainsMono.tar.xz -C "$FONT_DIR"
    fc-cache -fv
    echo "Fonts installed."
fi

# Apply config files
echo "Applying configs..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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
cp "$SCRIPT_DIR/.local/bin/"* "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/kb-layout" "$HOME/.local/bin/brightness" "$HOME/.local/bin/volume" "$HOME/.local/bin/resolution" "$HOME/.local/bin/nightlight"

# Install bluetui (TUI Bluetooth manager, system-wide)
BLUETUI_URL="https://github.com/pythops/bluetui/releases/download/v0.8.1/bluetui-x86_64-linux-musl"
BLUETUI_BIN="/usr/local/bin/bluetui"
if [ -f "$BLUETUI_BIN" ]; then
    echo "bluetui already installed, skipping."
else
    echo "Downloading bluetui..."
    sudo curl -L "$BLUETUI_URL" -o "$BLUETUI_BIN"
    sudo chmod +x "$BLUETUI_BIN"
    echo "bluetui installed."
fi

# Ensure ~/.local/bin is in PATH
case ":$PATH:" in
    *:"$HOME/.local/bin":*) ;;
    *) echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" ;;
esac

# Add nnn quitcd wrapper to .bashrc if not already there
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

echo "Configs applied to ~/.config/"

echo ""
echo "===== Setup complete ====="
echo "Reboot or run 'labwc' from tty1 to start your new desktop."
echo "Press Super+Space to launch apps (wofi)."
