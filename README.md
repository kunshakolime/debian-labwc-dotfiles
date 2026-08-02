# dotfiles

Labwc Wayland desktop config on Debian Trixie, managed with setup scripts.

One script, two modes:
- **Bare metal** (`setuplabwc.sh`) — full desktop with bluetooth, brightness, blue light filter
- **VPS** (`setuplabwc.sh --vps <password>`) — remote desktop via noVNC, no hardware deps

## Contents

| File/Dir | What it is |
|---|---|
| `setuplabwc.sh` | Setup: bare metal by default, VPS with `--vps <password>` (noVNC via distro wayvnc, no compiling) |
| `vps/.config/` | VPS-only configs (autostart with VNC, rc.xml without brightness, waybar without bluetooth/battery); overlaid by `--vps` mode |
| `uninstall-vps.sh` | Removes VPS setup (VNC, noVNC, headless env, autostart) without removing packages |
| `.config/labwc/` | Labwc window manager config (keybinds, theme, autostart) |
| `.config/waybar/` | Waybar status bar (clock, network, audio, bluetooth, battery, taskbar, weather, stats) |
| `.config/wofi/` | App launcher config (dark, Nerd Font) |
| `.config/foot/` | Foot terminal (dark colors, JetBrainsMono) |
| `.config/dunst/` | Notification daemon config |
| `.config/gtk-3.0/` | GTK3 dark theme (Numix) |
| `.config/gtk-4.0/` | GTK4 dark theme (Numix) |
| `.config/mimeapps.list` | Default apps: imv for images |
| `.local/share/applications/` | Custom desktop entries |
| `.local/bin/` | Scripts (volume, brightness, kb-layout, resolution, nightlight, power, clipboard, wallpaper) |
| `vendor/` | Offline assets: `fonts/` (JetBrainsMono Nerd Font) and `bluetui` binary |

## Offline reinstall / new user

Setup only talks to the network for `apt` packages — everything else ships in the
repo, so you can re-run `setuplabwc.sh` any time without internet:
- Fonts are installed from `vendor/fonts/`, bluetui from `vendor/bluetui`
- No downloads during setup (the `*.tar.xz` in `.gitignore` no longer matters)


## Bare metal install

```bash
sudo git clone https://github.com/kunshakolime/debian-labwc-dotfiles.git /opt/labwc_dotfiles
/opt/labwc_dotfiles/setuplabwc.sh
```

### Packages (bare metal)

labwc, waybar, wofi, foot, swaybg, wlsunset, dunst, cliphist, wl-clipboard, grim, slurp, swappy, jq, curl, btop, nnn, vim, tmux, fastfetch, pipewire, pipewire-pulse, libspa-0.2-bluetooth, wireplumber, pamixer, pulsemixer, playerctl, bluez, brightnessctl, network-manager, network-manager-gnome, imv, bluetui, xdg-desktop-portal, xdg-desktop-portal-gtk, xdg-desktop-portal-wlr, vlc, firefox-esr, numix-gtk-theme, JetBrainsMono Nerd Font

## VPS install

```bash
sudo git clone https://github.com/kunshakolime/debian-labwc-dotfiles.git /opt/labwc_dotfiles
/opt/labwc_dotfiles/setuplabwc.sh --vps <your-vnc-password>
```

Open `https://<vps-ip>:6080/vnc.html`, log in with username **user** and the password you set. Run `labwc` from a TTY to start the desktop. (noVNC auth requires HTTPS; a self-signed cert is generated — accept the warning.)

Alternatively, run it in a container (host stays clean, ports bind via host networking):

```bash
podman run -d --name labwc-vps --network host -v /opt/labwc_dotfiles:/repo:ro debian:trixie bash -c 'apt-get update && apt-get install -y --no-install-recommends sudo xz-utils && HOME=/root /repo/setuplabwc.sh --vps <your-vnc-password> && export XDG_RUNTIME_DIR=/tmp/xdg && mkdir -p /tmp/xdg && chmod 700 /tmp/xdg && exec labwc'
```

Same URLs; `podman logs labwc-vps` shows progress, `podman stop labwc-vps` stops it.

Also started: `http://<vps-ip>:6081/vnc.html` (plain HTTP, for localhost or as an HTTPS reverse-proxy backend — proxy `/` and `/websockify` to `http://127.0.0.1:6081`).

Phone use: in noVNC set **Resize → Remote**; the desktop resizes to match the viewport.

### Packages (VPS)

Same as bare metal minus: wlsunset, bluez, libspa-0.2-bluetooth, brightnessctl, network-manager, wlr-randr

Added: wayvnc, novnc, websockify, xwayland

### Uninstall VPS setup

Removes VNC, noVNC, headless env vars, and restores the default autostart. Does not remove packages.

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
| `Super` + `1..9` | Switch workspace |
| `Super` + `Shift` + `1..9` | Move window to workspace |
| `Super` + `p` | Power menu (lock / suspend / reboot / shutdown) |
| `Super` + `v` | Clipboard history (cliphist + wofi) |
| `Super` + `w` | Wallpaper picker + rotation (wofi) |
| `Super` + `PrtSc` / `Shift` + `PrtSc` | Full screenshot / area → edit in swappy |
| `Super` + `Up` / `Down` | Volume ±5% |
| `Super` + `m` | Toggle mute |
| Media keys | Playback control |
| Brightness keys | Backlight ±2% *(bare metal only)* |

## Wallpaper

`Super+w` opens a wofi picker (also in the app menu / right-click menu):

- Pick any image in `Pictures/Wallpapers/` — applied instantly, remembered at next login
- **Rotation**: `Rotate: off` / every 10 min / 30 min / 1 hour
- **Rotation set…**: toggle ✓/✗ to choose *which* wallpapers rotate (defaults to all)

State lives in `~/.config/wallpaper.conf` (`WALLPAPER`, `ROTATE_INTERVAL`, `ROTATE_SET`).
Rotation runs as a tiny `sleep` loop (`wallpaper-rotate`) — no extra daemon. Drop new
wallpapers into `Pictures/Wallpapers/` and add them to the rotation set from the menu.

## Waybar clicks

| Module | Click action |
|--------|-------------|
| CPU/RAM stats | `btop` |
| Network | `nmtui` (or the tray icon via nm-applet) |
| Audio | `pulsemixer` |
| Bluetooth | `bluetui` *(bare metal only)* |
| Display | Resolution picker (wofi + wlr-randr) *(bare metal only)* |

## Scripts

- `brightness up` / `brightness down` — backlight ±2% *(bare metal only)*
- `volume up` / `volume down` / `volume mute` — audio control
- `kb-layout` — cycle keyboard layout
- `resolution` — display resolution picker
- `power` — power menu (lock / suspend / reboot / shutdown)

## Planned

- **Screen locker + idle (swaylock + swayidle)** — `Super+L` to lock, autolock
  on inactivity, and DPMS (screen off after N min). Nothing locks the screen
  today. When added: `apt install swaylock swayidle`, start `swaylock` from
  the power menu (already wired), and run `swayidle` in the background from
  autostart.

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
