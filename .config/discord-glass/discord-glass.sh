#!/usr/bin/env bash
# Launch Discord with BetterDiscord injection guaranteed and a localhost-only
# DevTools port so the island and the CSS verifier can read what Discord shows.
# bd-reinject only writes when the host tree is missing the BD require line.
"$HOME/.local/bin/bd-reinject.sh" >/dev/null 2>&1 || true
exec /usr/bin/discord --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 "$@"
