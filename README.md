# dotfiles

Labwc Wayland desktop config on Debian Trixie, managed with setup scripts.

Two install modes:
- **Bare metal** (`setuplabwc.sh`) — full desktop with bluetooth, brightness, blue light filter
- **VPS** (`setuplabwc-vps.sh`) — remote desktop via noVNC with audio forwarding, no hardware deps

## Contents

| File/Dir | What it is |
|---|---|
| `setuplabwc.sh` | Bare metal setup: installs packages, copies configs, sets up fonts |
| `setuplabwc-vps.sh` | VPS setup: adds noVNC, sound, strips hardware deps. Takes VNC password as argument |
| `uninstall-vps.sh` | Removes VPS services/autostart without removing packages |
| `services/` | Systemd user service files for wayvnc and noVNC |
| `bashrc` | Shell config with nnn quitcd wrapper (`n()` function) |
| `.config/labwc/` | Labwc window manager config (keybinds, theme, autostart) |
| `.config/waybar/` | Waybar status bar (clock, network, audio, bluetooth, battery, taskbar, weather, stats) |
| `.config/wofi/` | App launcher config (dark, Nerd Font) |
| `.config/foot/` | Foot terminal (dark colors, JetBrainsMono) |
| `.config/dunst/` | Notification daemon config |
| `.config/gtk-3.0/` | GTK3 dark theme (Numix) |
| `.config/gtk-4.0/` | GTK4 dark theme (Numix) |
| `.config/mimeapps.list` | Default apps: imv for images |
| `.local/share/applications/` | Custom desktop entries |
| `.local/bin/` | Scripts (volume, brightness, kb-layout, resolution, nightlight) |

## Bare metal install

```bash
sudo git clone https://github.com/kunshakolime/debian-labwc-dotfiles.git /opt/labwc_dotfiles
/opt/labwc_dotfiles/setuplabwc.sh
```

### Packages (bare metal)

labwc, waybar, wofi, foot, swaybg, wlsunset, dunst, copyq, wl-clipboard, grim, slurp, jq, curl, btop, nnn, vim, tmux, fastfetch, pipewire, pipewire-pulse, libspa-0.2-bluetooth, wireplumber, pamixer, pulsemixer, playerctl, bluez, brightnessctl, network-manager, imv, bluetui, xdg-desktop-portal, xdg-desktop-portal-gtk, vlc, firefox-esr, numix-gtk-theme, JetBrainsMono Nerd Font

## VPS install

Sets up labwc with noVNC (browser-based VNC) and PulseAudio TCP for audio forwarding over VNC.

```bash
sudo git clone https://github.com/kunshakolime/debian-labwc-dotfiles.git /opt/labwc_dotfiles
/opt/labwc_dotfiles/setuplabwc-vps.sh <your-vnc-password>
```

After setup, open `http://<vps-ip>:6080/vnc.html` in a browser and enter the password. Run `labwc` from a TTY to start the desktop.

### Packages (VPS)

Same as bare metal minus: wlsunset, bluez, libspa-0.2-bluetooth, brightnessctl, network-manager, wlr-randr

Added: wayvnc, novnc, websockify, xwayland, xdg-desktop-portal-wlr

### Uninstall VPS setup

Removes VNC services, noVNC proxy, PulseAudio TCP, and restores default autostart. Does not remove packages.

```bash
/opt/labwc_dotfiles/uninstall-vps.sh
```

## Keybinds

| Keys | Action |
|------|--------|
| `Super` + `Space` | App launcher (wofi) |
| `Super` + `Enter` | Terminal (footclient) |
| `Super` + `q` | Close window |
| `Super` + `Tab` / `Shift` + `Tab` | Cycle windows |
| `Super` + `PrtSc` / `Shift` + `PrtSc` | Full / area screenshot |
| `Super` + `Up` / `Down` | Volume ±5% |
| `Super` + `m` | Toggle mute |
| Media keys | Playback control |
| Brightness keys | Backlight ±2% *(bare metal only)* |

## Waybar clicks

| Module | Click action |
|--------|-------------|
| CPU/RAM stats | `btop` |
| Network | `nmtui` |
| Audio | `pulsemixer` |
| Bluetooth | `bluetui` *(bare metal only)* |
| Display | Resolution picker (wofi + wlr-randr) *(bare metal only)* |

## Scripts

- `brightness up` / `brightness down` — backlight ±2% *(bare metal only)*
- `volume up` / `volume down` / `volume mute` — audio control
- `kb-layout` — cycle keyboard layout
- `resolution` — display resolution picker

## imv (image viewer)

| Keys | Action |
|------|--------|
| `←` / `→` | Previous / next image |
| `↑` / `↓` | Zoom in / out |
| `i` / `o` | Zoom in / out |
| `+` / `-` | Zoom in / out |
| `j` / `k` | Pan up / down |
| `h` / `l` | Pan left / right |
| `q` | Quit |
| `f` | Fullscreen |
| `x` | Close current image |
| `r` | Reset zoom and pan |
| `a` | Actual size |
| `c` | Center image |
| `d` | Toggle info overlay |
| `s` / `S` | Next scaling / upscaling mode |
| `p` | Print to stdout |

Run `n` instead of `nnn` to auto-cd to last directory on quit.
