# RedsDotfiles

Portable dotfiles for Fedora, Hyprland, and ML4W.

## Layout

- `.config/` — user configuration and application settings
- `.tmux.conf` — tmux configuration
- `.bashrc`, `.zshrc`, `.Xresources`, `.gtkrc-2.0` — home-directory settings
- `bash/`, `zsh/`, `git/`, `gtk/`, `zshrc/` — per-app configuration layout
- `config.dotinst` — ML4W restore metadata

Real files only, with machine-specific paths and credentials kept out where possible.

## Secrets and local data

No credentials belong in this repository. Keep local API keys in the untracked `~/.zshrc.local` file. Git identity and GTK file-manager bookmarks are intentionally excluded. Remote restore owner/repository values in `config.dotinst` are placeholders.

Wallpapers, caches, logs, and generated files are not tracked.

## Wallpaper-responsive rice

The wallpaper script derives an Everforest-shaped accent from the active wallpaper and feeds it to Matugen. The generated palette updates the desktop, window borders, terminal, tmux, application themes, and other configured apps. The checked-in templates make those settings reproducible; machine-specific wallpapers and generated caches remain local.

## Log

### ThinkPad T495 laptop integration (2026-09-29)

- Fedora 43, Ryzen 7 PRO 3700U / integrated Vega, 1920x1080 60 Hz panel.
- GPU autodetection and preferred monitor modes replace desktop-specific device nodes.
- Glass blur uses size 3 and one pass, with a smaller shadow range (12).
- Wallpaper colors use Fedora's `/usr/bin/python3` with its installed Pillow.
- Local Neovim, keybindings, password/fingerprint authentication, wallpaper locking,
  shell settings, bookmarks, and idle display power-off behavior are preserved.
- Optional upstream app injectors and user services are not installed or enabled.
  Existing Matugen outputs are retained rather than modifying unrelated apps.
- Run `bash .config/hypr/scripts/check-laptop.sh` for a non-disruptive check.
  Validate Hyprland with `Hyprland --verify-config -c ~/.config/hypr/hyprland.conf`.
- System tuning is unchanged: this laptop currently uses `throughput-performance`.
  To opt into general-purpose balanced tuning, run `sudo tuned-adm profile balanced`.
  No extra power manager, kernel arguments, or battery charge thresholds are added.
- The pre-update checkout and local tmux settings are backed up under
  `~/.local/state/dotfiles-backups/20260929-1926/`. The original Git commit is
  recorded there in `original-head`, with uncommitted edits in `local.patch`.

- Resynced the ML4W configuration and added portable wallpaper-responsive colors, app themes, tmux/kitty integration, Discord Home branding, and compact GitHub Desktop titlebar styling.
