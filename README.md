# dotfiles

Labwc Wayland desktop config on Debian Trixie, managed with a setup script.

## Contents

| File/Dir | What it is |
|---|---|
| `setuplabwc.sh` | One-shot setup: installs packages, copies configs, sets up fonts |
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
| `.local/bin/` | Scripts (volume, brightness, kb-layout) |

## Packages

labwc, waybar, wofi, foot, swaybg, wlsunset, dunst, copyq, wl-clipboard, grim, slurp, jq, curl, btop, nnn, vim, tmux, fastfetch, pipewire, pipewire-pulse, libspa-0.2-bluetooth, wireplumber, pamixer, pulsemixer, playerctl, bluez, brightnessctl, network-manager, imv, bluetui, xdg-desktop-portal, xdg-desktop-portal-gtk, vlc, firefox-esr, numix-gtk-theme, JetBrainsMono Nerd Font

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
| Brightness keys | Backlight ±2% |

## Waybar clicks

| Module | Click action |
|--------|-------------|
| CPU/RAM stats | `btop` |
| Network | `nmtui` |
| Audio | `pulsemixer` |
| Bluetooth | `bluetui` |
| Display | Resolution picker (wofi + wlr-randr) |

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

## Scripts

- `brightness up` / `brightness down` — backlight ±2%
- `volume up` / `volume down` / `volume mute` — audio control
- `kb-layout` — cycle keyboard layout

## Usage

```bash
# Clone to /opt so all users can use it, then run the setup
sudo git clone https://github.com/kunshakolime/debian-labwc-dotfiles.git /opt/dotfiles
/opt/dotfiles/setuplabwc.sh
```

Run `n` instead of `nnn` to auto-cd to last directory on quit.
