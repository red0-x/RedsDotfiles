#!/usr/bin/sh
# Re-inject BetterDiscord into Discord's desktop_core module.
# Discord host updates create a fresh app-<version>/ tree, wiping the injection.

BD_ASAR="$HOME/.config/BetterDiscord/data/betterdiscord.asar"
[ -f "$BD_ASAR" ] || exit 0

# Discord extracts modules a little after creating app-<version>/, so retry.
i=0
while [ "$i" -lt 24 ]; do
    found=0
    for f in "$HOME"/.config/discord/app-*/modules/discord_desktop_core-*/discord_desktop_core/index.js; do
        [ -f "$f" ] || continue
        found=1
        grep -q 'betterdiscord.asar' "$f" && continue
        printf 'require("%s");\nmodule.exports = require("./core.asar");\n' "$BD_ASAR" > "$f"
        echo "bd-reinject: injected $f"
    done
    [ "$found" -eq 1 ] && exit 0
    i=$((i + 1))
    sleep 5
done
