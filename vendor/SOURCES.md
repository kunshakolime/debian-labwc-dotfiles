# Sources

These files are vendored so setup can run fully offline (only `apt` needs
network). All credit goes to their authors:

| File | Project | License |
|---|---|---|
| `fonts/JetBrainsMonoNerdFont-Regular.ttf` | [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) — patched JetBrains Mono | SIL Open Font License 1.1 |
| `fonts/JetBrainsMonoNerdFont-Bold.ttf` | [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) — patched JetBrains Mono | SIL Open Font License 1.1 |
| `bluetui` | [pythops/bluetui](https://github.com/pythops/bluetui) v0.8.1 (`bluetui-x86_64-linux-musl`) | GPL-3.0 |
| `sshm-askpass/setup-sshm-askpass.sh` | [debian-13-tricks](https://github.com/kunshakolime/debian-13-tricks) `setups/sshm-askpass/` | ours (unlicensed) |

- Fonts extracted from `JetBrainsMono.tar.xz` from the latest [Nerd Fonts release](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz).
- bluetui binary from its [v0.8.1 release](https://github.com/pythops/bluetui/releases/tag/v0.8.1).
- Retrieved 2026-08-02. Update by re-downloading the source and re-vendoring here.
- JetBrains Mono is by JetBrains; the Nerd Fonts patch adds icon glyphs used by
  waybar/fuzzel/dunst/foot configs. bluetui is GPL-3.0 and provided as-is.
