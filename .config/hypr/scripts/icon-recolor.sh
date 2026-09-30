#!/usr/bin/env bash
# Recolor Colloid-Rice-Dark folder icons to the current matugen primary.
# Called as a matugen post_hook. Source icons: Colloid-Green-Dark (#66BB6A).
I="$HOME/.local/share/icons"
SRC="$I/Colloid-Green-Dark/places/scalable"
DST="$I/Colloid-Rice-Dark/places/scalable"
C="$(tr -d '#\n ' < "$HOME/.config/ml4w/colors/primary")"
[[ "$C" =~ ^[0-9a-fA-F]{6}$ ]] || exit 0
grep -rlEi '66BB6A' "$SRC" | while read -r f; do
  sed "s/#66[Bb][Bb]6[Aa]/#$C/g" "$f" > "$DST/$(basename "$f")"
done
gtk-update-icon-cache -f -q "$I/Colloid-Rice-Dark" 2>/dev/null
# nudge running GTK apps to reload icons
gsettings set org.gnome.desktop.interface icon-theme 'Colloid-Green-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'Colloid-Rice-Dark'
# GTK4 apps (Nautilus) only read colors.css at startup: restart the background
# Nautilus service if it has no open windows, so the next window gets new colors.
if ! hyprctl clients -j | grep -q '"class": "org.gnome.Nautilus"'; then nautilus -q 2>/dev/null || true; fi
