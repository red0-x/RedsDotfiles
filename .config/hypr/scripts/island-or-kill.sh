#!/usr/bin/env bash
# Super+Q: dismiss an open dynamic island first, otherwise close the active window.
if qs ipc -c island call island isopen 2>/dev/null | grep -qx true; then
    qs ipc -c island call island close
else
    hyprctl dispatch killactive
fi
