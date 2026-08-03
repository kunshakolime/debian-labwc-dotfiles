# dotfiles

Labwc Wayland desktop config on Debian Trixie, managed with setup scripts.

One script, two modes:
- **Bare metal** (`setuplabwc.sh`) — full desktop with bluetooth, brightness, blue light filter
- **VPS** (`setuplabwc.sh --vps <password>`) — remote desktop via noVNC, no hardware deps

## Contents

| File/Dir | What it is |
|---|---|
| `setuplabwc.sh` | Setup: bare metal by default, VPS with `--vps <password>` |
| `vps/.config/` | VPS-only configs (VNC autostart, waybar without bluetooth/battery) |
| `uninstall-vps.sh` | Removes VPS setup (VNC, noVNC, headless env, autostart) without removing packages |
| `uninstall.sh` | Removes the desktop setup (configs, scripts, bashrc additions) without removing packages |
| `.config/labwc/` | Labwc window manager config (keybinds, theme, autostart) |
| `.config/waybar/` | Waybar status bar (clock, network, audio, bluetooth, battery, taskbar, weather, stats) |
| `.config/fuzzel/` | App launcher config (dark, Nerd Font) |
| `.config/foot/` | Foot terminal (dark colors, JetBrainsMono) |
| `.config/dunst/` | Notification daemon config |
| `.config/gtk-3.0/` | GTK3 dark theme (Adwaita dark) |
| `.config/gtk-4.0/` | GTK4 dark theme (Adwaita dark) |
| `.config/mimeapps.list` | Default apps: Loupe for images |
| `.local/share/applications/` | Custom desktop entries |
| `.local/bin/` | Scripts (volume, brightness, kb-layout, resolution, nightlight, power, clipboard, wallpaper, mount-net) |
| `vendor/` | Offline assets: `fonts/` (JetBrainsMono Nerd Font) and `bluetui` binary |

## Install

Everything except `apt` packages ships in the repo, so re-running setup needs no
internet (fonts from `vendor/fonts/`, bluetui from `vendor/bluetui`).

### Bare metal

```bash
sudo git clone https://github.com/kunshakolime/debian-labwc-dotfiles.git /opt/labwc_dotfiles
/opt/labwc_dotfiles/setuplabwc.sh
```

Run as the desktop user (configs go to their home; user added to `video` group for
brightness keys). Running as root sets up `/root` instead. Reset with `uninstall.sh`.

### Packages (bare metal)

labwc, waybar, fuzzel, foot, swaybg, wlsunset, dunst, cliphist, wl-clipboard, grim, slurp, swappy, jq, curl, btop, nnn, vim, tmux, fastfetch, pipewire, pipewire-pulse, libspa-0.2-bluetooth, wireplumber, pamixer, pulsemixer, playerctl, bluez, brightnessctl, network-manager, network-manager-gnome, gnome-disk-utility, loupe, bluetui, davfs2, cifs-utils, sshfs, xdg-desktop-portal, xdg-desktop-portal-gtk, xdg-desktop-portal-wlr, vlc, firefox-esr, JetBrainsMono Nerd Font

## VPS

```bash
sudo git clone https://github.com/kunshakolime/debian-labwc-dotfiles.git /opt/labwc_dotfiles
/opt/labwc_dotfiles/setuplabwc.sh --vps <your-vnc-password>
```

VNC in a browser: `https://<vps-ip>:6080/vnc.html` (user **user**, accept the
self-signed cert), or `http://<vps-ip>:6081/vnc.html` for localhost/reverse-proxy
backends. On phones set **Resize → Remote**. Run `labwc` from a TTY to start.

Container option (host stays clean):

```bash
podman run -d --name labwc-vps --network host -v /opt/labwc_dotfiles:/repo:ro debian:trixie bash -c 'apt-get update && apt-get install -y --no-install-recommends sudo xz-utils && HOME=/root /repo/setuplabwc.sh --vps <your-vnc-password> && export XDG_RUNTIME_DIR=/tmp/xdg && mkdir -p /tmp/xdg && chmod 700 /tmp/xdg && exec labwc'
```

`podman logs` / `podman stop` control it.

### Packages (VPS)

Same as bare metal minus: wlsunset, bluez, libspa-0.2-bluetooth, brightnessctl,
network-manager, wlr-randr, gnome-disk-utility

Added: wayvnc, novnc, websockify, xwayland, zram-tools (compressed swap, 50% of
RAM, enabled automatically). Optional on bare metal:

```bash
sudo apt install zram-tools
sudo systemctl enable --now zramswap  # default: /etc/default/zramswap ALGO=zstd PERCENT=50
```

### Uninstall VPS setup

```bash
/opt/labwc_dotfiles/uninstall-vps.sh
```

Removes VNC, noVNC, headless env vars, and restores the default autostart
(packages are kept).

## Keybinds

| Keys | Action |
|------|--------|
| `Super` + `Space` | App launcher (fuzzel) |
| `Super` + `Enter` | Terminal (footclient) |
| `Super` + `q` | Close window |
| `Super` + `Tab` / `Shift` + `Tab` | Cycle windows |
| `Super` + `1..9` | Switch workspace |
| `Super` + `Shift` + `1..9` | Move window to workspace |
| `Super` + `p` | Control center (clipboard, wallpaper, layout, power, widgets) |
| `Super` + `b` | Toggle the whole waybar (hide/show) |
| `Super` + `PrtSc` / `Shift` + `PrtSc` | Full screenshot / area → edit in swappy |
| `Super` + arrows | Snap window to edge |
| Media keys | Volume / playback control |
| Brightness keys | Backlight ±2% *(bare metal only)* |

## Wallpaper

`Super+p` → **Wallpaper** (also in the right-click menu):

- Pick any image in `Pictures/Wallpapers/` — applied instantly, remembered at next login
- **Rotation**: off / every 10 min / 30 min / 1 hour
- **Rotation set…**: ✓/✗ which wallpapers rotate (defaults to all)

State in `~/.config/wallpaper.conf`. Rotation is a tiny `sleep` loop
(`wallpaper-rotate`), no daemon.

## Network mounts (WebDAV / SMB / SFTP)

`mount-net` writes the systemd units and credentials for you — no config files.
Shares live at `/mnt/<name>`.

```bash
mount-net add nas     # asks type, URL/server, login
mount-net status      # which shares, mode, mounted?
mount-net keep nas    # mount at boot, never auto-unmount
mount-net auto nas    # mount on access, unmount after 5 min idle (default)
mount-net mount nas   # mount now (or: umount, remove, list)
```

Two modes: **auto** (default) and **keep** (always connected); flip anytime.
SFTP uses key login (`ssh-copy-id` once). No daemons run while unmounted.

## Quick Share (packet)

Installed from a prebuilt `.deb`. Bluetooth on both sides, visibility "Everyone
nearby".

**Limitation:** fails when the *phone* hosts the hotspot (Android doesn't forward
mDNS). Flip it — make the *laptop* the hotspot:

```bash
nmcli connection add type wifi ifname wlo1 con-name packet-ap mode ap \
  ssid packet-ap ipv4.method shared ipv6.method shared autoconnect no
nmcli connection up packet-ap
# afterwards, rejoin your phone's hotspot:
nmcli connection up <phone-hotspot-name>
```

## Waybar clicks

| Module | Click action |
|--------|-------------|
| CPU/RAM stats | `btop` |
| Network | `nmtui` (or the tray icon via nm-applet) |
| Audio | `pulsemixer` |
| Bluetooth | `bluetui` *(bare metal only)* |
| Display | Resolution picker (fuzzel + wlr-randr) *(bare metal only)* |

## Scripts

- `brightness up` / `brightness down` — backlight ±2% *(bare metal only)*
- `volume up` / `volume down` / `volume mute` — audio control
- `kb-layout` — cycle keyboard layout
- `resolution` — display resolution picker
- `power` — power menu (lock / suspend / reboot / shutdown)
- `control` — flat control center (clipboard, wallpaper, layout, resolution, night light, waybar widgets, power); desktop-only entries auto-hide on VPS
- `widgets` — toggle which waybar widgets show (edits `modules-*`; fixed menu order, disabled widgets stay in place marked ✗; each toggle applies immediately and the menu re-highlights your last row; original slots restored via `.widgets-state`)
- `bar` — toggle the whole waybar on/off (`Super+b`)
- `menu <command>` — toggle any fuzzel-based menu (second press closes)
- `mount-net` — add/remove/mount network shares (WebDAV, SMB, SFTP)

## Planned

- **Screen locker + idle (swaylock + swayidle)** — `Super+L` to lock, autolock
  on inactivity, DPMS screen-off. Nothing locks today; `swaylock` is already
  wired into the power menu.

## Image viewer

Images open in **Loupe** (GNOME image viewer), set as default in
`.config/mimeapps.list`.

Run `n` instead of `nnn` to auto-cd to last directory on quit.
