#!/usr/bin/env bash
# GitHub Desktop with the glass CSS injected over the local debug port.
#
# No titleBarStyle override: "custom" makes GitHub Desktop draw its own
# title bar, and ghdesktop-glass.css hides #desktop-app-title-bar, which
# removes the menu and window controls entirely. Native title bar keeps the
# menu usable and the CSS still styles the rest of the window.
config="$HOME/.var/app/io.github.shiftey.Desktop/config/GitHub Desktop/.title-bar-config"
mkdir -p "$(dirname "$config")"
rm -f "$config"
exec flatpak run io.github.shiftey.Desktop --remote-debugging-port=9231 --remote-debugging-address=127.0.0.1 "$@"
