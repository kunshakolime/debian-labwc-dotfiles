# dotfiles

Labwc Wayland desktop config on Debian Trixie, managed with setup scripts.

Two install modes:
- **Bare metal** (`setuplabwc.sh`) — full desktop with bluetooth, brightness, blue light filter
- **VPS** (`setuplabwc-vps.sh`) — remote desktop via noVNC, no hardware deps

## Contents

| File/Dir | What it is |
|---|---|
| `setuplabwc.sh` | Bare metal setup: installs packages, copies configs, sets up fonts |
| `setuplabwc-vps.sh` | VPS setup: adds noVNC, sound, strips hardware deps. Takes VNC password as argument |
| `build-wayvnc.sh` | Builds wayvnc >= 0.10 from source (for Trixie's old 0.9.1); no-op if not needed |
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
| `.local/bin/` | Scripts (volume, brightness, kb-layout, resolution, nightlight) |

## Bare metal install

```bash
sudo git clone https://github.com/kunshakolime/debian-labwc-dotfiles.git /opt/labwc_dotfiles
/opt/labwc_dotfiles/setuplabwc.sh
```

### Packages (bare metal)

labwc, waybar, wofi, foot, swaybg, wlsunset, dunst, copyq, wl-clipboard, grim, slurp, jq, curl, btop, nnn, vim, tmux, fastfetch, pipewire, pipewire-pulse, libspa-0.2-bluetooth, wireplumber, pamixer, pulsemixer, playerctl, bluez, brightnessctl, network-manager, imv, bluetui, xdg-desktop-portal, xdg-desktop-portal-gtk, vlc, firefox-esr, numix-gtk-theme, JetBrainsMono Nerd Font

## VPS install

Sets up labwc with noVNC (browser-based VNC). Note: VNC has no audio channel — sound plays from the machine's own output only (PipeWire stack starts from the labwc autostart).

```bash
sudo git clone https://github.com/kunshakolime/debian-labwc-dotfiles.git /opt/labwc_dotfiles
/opt/labwc_dotfiles/setuplabwc-vps.sh <your-vnc-password>
```

After setup, open `http://<vps-ip>:6080/vnc.html` in a browser and enter the VNC password. Run `labwc` from a TTY to start the desktop.

Phone use: in noVNC click the settings gear and set **Resize → Remote**. The headless desktop is resized on demand — rotate the phone to portrait and the VNC server (wayvnc 0.10.1, `enable_resizing` on by default) resizes the output to match the phone's viewport, so it fills the screen instead of being a tiny landscape window.

The patched wayvnc build (or Forky's 0.10.1 built by `build-wayvnc.sh`) offers classic VNC password auth first, so noVNC shows a simple password-only prompt over plain HTTP — no self-signed cert warning, no username.

### wayvnc from source (Debian Trixie)

Trixie ships wayvnc 0.9.1, which lacks `allow_broken_crypto`. `build-wayvnc.sh` compiles aml → neatvnc → wayvnc 0.10.1 into `/usr/local` (pinned release tags, no FFmpeg needed) and is called automatically by `setuplabwc-vps.sh` when the installed wayvnc is older than 0.10 (or a previous source build is absent). Re-running it is a no-op once the patched build is installed; `./build-wayvnc.sh --force` rebuilds anyway.

It also applies `patches/neatvnc-vnc-auth-first.diff`, which makes neatvnc offer classic VNC auth (type 2) first. Upstream lists RSA-AES/AppleDH before it, so noVNC picks those and shows a username+password prompt.

### Packages (VPS)

Same as bare metal minus: wlsunset, bluez, libspa-0.2-bluetooth, brightnessctl, network-manager, wlr-randr

Added: wayvnc, novnc, websockify, xwayland, xdg-desktop-portal-wlr

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
