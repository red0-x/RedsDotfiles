#!/usr/bin/env bash
# Copy the current wallpaper into the Brave new-tab extension (extensions can't read ~/Pictures).
wp="$(cat "$HOME/.cache/ml4w/hyprland-dotfiles/current_wallpaper" 2>/dev/null)"
[ -f "$wp" ] || exit 0
magick "$wp" -resize '1920x1080^' -quality 85 "$HOME/.config/brave-glass-newtab/wallpaper.jpg" 2>/dev/null \
  || cp "$wp" "$HOME/.config/brave-glass-newtab/wallpaper.jpg"
