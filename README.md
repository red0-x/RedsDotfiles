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

## Rice extras (injectors, island, waybar)

- `.config/rice-stars/electron-inject.mjs`: CDP injector. Usage `node electron-inject.mjs <port> <css> [stars]`. Loads the CSS (and an optional sibling `.js`) into an Electron app's pages.
- `.config/{slack,claude,steam,ghdesktop,discord,brave}-glass/`: per-app launchers (localhost-only debug port) plus user services in `.config/systemd/user/`. Generated `*-glass.css` come from `matugen/templates/`. Claude needs `claude-glass/patch-app-asar.mjs` (see its README).
- BetterDiscord: `RpcBridge` (writes `~/.cache/discord-*.json`), `RiceStars`, `RiceHomeLogo` plugins. `bd-reinject.sh` plus `bd-reinject.path/.service` re-patch Discord after host updates. Install BetterDiscord itself first (the asar is not tracked).
- `.config/quickshell/island/`: dynamic island over the bar (see its README). Needs `quickshell`, `cava`, `jq`. `.local/bin/{rice-toast,jcode-toast,island-restart.sh,toast-watch-restart.sh}` feed it.
- `.config/waybar/`: `modules.json` (Discord, GPU, disk chips, island click actions) and `scripts/`. Palette via matugen.
- The `quickshell/overview` workspace switcher is a third-party clone, not tracked. Matugen renders its colors from `matugen/templates/quickshell-overview.qml`.
- Enable services: `systemctl --user enable --now slack-glass claude-glass steam-glass ghdesktop-glass bd-reinject.path`.

## Log

- Resynced the ML4W configuration and added portable wallpaper-responsive colors, app themes, tmux/kitty integration, Discord Home branding, and compact GitHub Desktop titlebar styling.
- Added app glass injectors, BetterDiscord RpcBridge and reinject, quickshell island, waybar Discord/GPU/disk chips and toast helpers.
