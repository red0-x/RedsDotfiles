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

- Resynced the ML4W configuration and added portable wallpaper-responsive colors, app themes, tmux/kitty integration, Discord Home branding, and compact GitHub Desktop titlebar styling.
