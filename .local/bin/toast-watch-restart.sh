#!/usr/bin/env bash
# Restart the notification sniffer without matching this shell's own cmdline.
pkill -f 'notify-watch[.]py' 2>/dev/null
sleep 0.4
setsid nohup python3 "$HOME/.config/quickshell/island/notify-watch.py" >"$HOME/.cache/notify-watch.log" 2>&1 &
