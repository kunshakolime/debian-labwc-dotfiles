#!/bin/bash
# Uninstall the desktop labwc setup: kill the UI stack, remove all configs,
# scripts, and bashrc additions. Does NOT remove packages or user files
# (wallpapers in Pictures/Wallpapers are kept).
#
# Run as the user whose setup you want to remove, then re-run setuplabwc.sh
# to start fresh.

echo "Stopping desktop session processes..."

pkill -x waybar 2>/dev/null || true
pkill -x dunst 2>/dev/null || true
pkill -x wlsunset 2>/dev/null || true
pkill -x swaybg 2>/dev/null || true
pkill -x nm-applet 2>/dev/null || true
pkill -x lxpolkit 2>/dev/null || true
pkill -f "foot --server" 2>/dev/null || true
pkill -f "wl-paste --watch cliphist" 2>/dev/null || true
pkill -f "wallpaper-rotate" 2>/dev/null || true
rm -f "${XDG_RUNTIME_DIR:-/tmp}/wallpaper-rotate.pid"

echo "Removing configs..."
rm -rf "$HOME/.config/labwc" \
       "$HOME/.config/waybar" \
       "$HOME/.config/fuzzel" \
       "$HOME/.config/foot" \
       "$HOME/.config/dunst" \
       "$HOME/.config/gtk-3.0" \
       "$HOME/.config/gtk-4.0" \
       "$HOME/.config/mimeapps.list" \
       "$HOME/.config/wallpaper.conf"
rm -f "$HOME/.local/state/nightlight"

echo "Removing scripts and desktop entries..."
rm -f "$HOME/.local/bin/volume" \
      "$HOME/.local/bin/brightness" \
      "$HOME/.local/bin/kb-layout" \
      "$HOME/.local/bin/resolution" \
      "$HOME/.local/bin/nightlight" \
      "$HOME/.local/bin/power" \
      "$HOME/.local/bin/clipboard" \
      "$HOME/.local/bin/wallpaper" \
      "$HOME/.local/bin/wallpaper-rotate" \
      "$HOME/.local/bin/mount-net"
rm -f "$HOME/.local/share/applications/"*.desktop
rm -f "$HOME/.local/share/applications/desktop-only/"*.desktop 2>/dev/null
rmdir "$HOME/.local/share/applications/desktop-only" 2>/dev/null || true

echo "Reverting bashrc additions..."
if [ -f "$HOME/.bashrc" ]; then
    sed -i '/^export PATH="$HOME\/.local\/bin:\$PATH"$/d' "$HOME/.bashrc"
    sed -i '/^# nnn — cd to last directory on exit (quitcd wrapper)$/,/^}/d' "$HOME/.bashrc"
fi

echo "Reverting dark theme preference..."
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme default 2>/dev/null || true
fi

echo ""
echo "Desktop setup removed."
echo "  - processes: killed"
  echo "  - configs: deleted (~/.config/labwc, waybar, fuzzel, foot, dunst, gtk-*)"
echo "  - scripts + .desktop entries: deleted"
echo "  - bashrc: PATH export + nnn wrapper removed"
echo "  - wallpapers: kept in ~/Pictures/Wallpapers"
echo ""
echo "Packages were NOT removed (apt remove them yourself if wanted)."
echo "Run ./setuplabwc.sh to install fresh."
