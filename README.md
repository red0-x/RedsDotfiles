# RedsDotfiles

Dotfiles for my Laptop and Workstation. Fedora + Hyprland, ML4W base.

## Layout

- `.config/` — mirror of `~/.mydotfiles/com.ml4w.dotfiles.stable/.config` (the ML4W source `~/.config` symlinks into). Source of truth.
- `.bashrc`, `.zshrc`, `.Xresources`, `.gtkrc-2.0` — home dotfiles
- `bash/`, `zsh/`, `git/`, `gtk/`, `zshrc/` — same content, per-app layout
- `config.dotinst/` — ML4W dotinst restore metadata

Real files only — no symlinks tracked, so a clone is usable on any machine.

## Secrets

No credentials in this repo. `~/.zshrc` sources `~/.zshrc.local` (untracked) for API keys.

## Not tracked

Wallpapers (`.config/ml4w/wallpapers/`), caches, logs, `*.bak`.

## Log

- **2026-07-29** — resynced from live: hyprexpo + borders-plus-plus, fcitx5 IME toggle, kicad-wakatime autostart, kdeconnect, voice-dictate bind, display-window kitty session, zsh productivity module (zoxide/fzf/yazi), polkit-mate agent, nvidia `WLR_DRM_DEVICES` + direct scanout. Onshape key pulled out of tracked `.zshrc`.
- **2026-04-12** — initial dotfiles added.
