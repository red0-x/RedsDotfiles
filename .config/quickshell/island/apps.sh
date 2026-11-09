#!/usr/bin/env bash
# Emit TAB-separated desktop entries for the island launcher.
for d in /usr/share/applications "$HOME/.local/share/applications" \
         /var/lib/flatpak/exports/share/applications \
         "$HOME/.local/share/flatpak/exports/share/applications"; do
    [ -d "$d" ] || continue
    find "$d" -maxdepth 1 -name '*.desktop' -print0 2>/dev/null | while IFS= read -r -d '' f; do
        grep -qm1 '^NoDisplay=true' "$f" && continue
        name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
        exec=$(grep -m1 '^Exec=' "$f" | cut -d= -f2-)
        icon=$(grep -m1 '^Icon=' "$f" | cut -d= -f2-)
        [ -n "$name" ] && [ -n "$exec" ] && printf '%s\t%s\t%s\n' "$name" "$exec" "$icon"
    done
done | sort -u -t$'\t' -k1,1
