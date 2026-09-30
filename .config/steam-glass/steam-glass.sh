#!/usr/bin/env bash
# Launch Steam with the CEF debug port enabled (the injector runs as the steam-glass user service).
touch "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/.cef-enable-remote-debugging"
exec flatpak run com.valvesoftware.Steam "$@"
