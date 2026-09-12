#!/usr/bin/env bash
if [ -f /usr/bin/waypaper ]; then
    echo ":: Launching waybar in /usr/bin"
    flock -x "$HOME/.cache/ml4w/waypaper.lock" waypaper $1 &
elif [ -f $HOME/.local/bin/waypaper ]; then
    echo ":: Launching waybar in $HOME/.local/bin"
    $HOME/.local/bin/flock -x "$HOME/.cache/ml4w/waypaper.lock" waypaper $1 &
else
    echo ":: waypaper not found"
fi
