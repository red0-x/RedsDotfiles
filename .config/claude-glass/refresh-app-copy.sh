#!/usr/bin/env bash
# Refresh the user-owned Claude Desktop copy after a system package update.
# Quit Claude first: the running binary cannot be replaced safely.
set -euo pipefail
src=/usr/lib/claude-desktop
dst="$HOME/.local/share/claude-desktop"
cp -a "$src/." "$dst/"
node "$HOME/.config/claude-glass/patch-app-asar.mjs" "$dst/resources/app.asar"
echo "Claude copy refreshed and patched. Relaunch Claude from the desktop entry."
