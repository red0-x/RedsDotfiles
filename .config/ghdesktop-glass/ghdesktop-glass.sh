#!/usr/bin/env bash
# GitHub Desktop with a localhost-only DevTools port (ghdesktop-glass service injects the theme).
config="$HOME/.var/app/io.github.shiftey.Desktop/config/GitHub Desktop/.title-bar-config"
mkdir -p "$(dirname "$config")"
printf '%s' '{"titleBarStyle":"custom"}' > "$config"
exec flatpak run io.github.shiftey.Desktop --remote-debugging-port=9231 --remote-debugging-address=127.0.0.1 "$@"
