#!/usr/bin/env bash
# Restart the quickshell island without matching this shell's own cmdline.
pkill -f 'qs -c island' 2>/dev/null
sleep 0.5
setsid nohup qs -c island >"$HOME/.cache/qs-island.log" 2>&1 &
