#!/usr/bin/env bash
#                _ _
# __      ____ _| | |_ __   __ _ _ __   ___ _ __
# \ \ /\ / / _` | | | '_ \ / _` | '_ \ / _ \ '__|
#  \ V  V / (_| | | | |_) | (_| | |_) |  __/ |
#   \_/\_/ \__,_|_|_| .__/ \__,_| .__/ \___|_|
#                   |_|         |_|
#
# -----------------------------------------------------
# Restore last wallpaper
# -----------------------------------------------------

# -----------------------------------------------------
# Set defaults
# -----------------------------------------------------

ml4w_cache_folder="$HOME/.cache/ml4w/hyprland-dotfiles"

defaultwallpaper="$HOME/.config/ml4w/wallpapers/default.jpg"

cachefile="$ml4w_cache_folder/current_wallpaper"

# -----------------------------------------------------
# Get current wallpaper
# -----------------------------------------------------

if [ -f "$cachefile" ]; then
    sed -i "s|~|$HOME|g" "$cachefile"
    wallpaper=$(cat $cachefile)
    if [ -f $wallpaper ]; then
        echo ":: Wallpaper $wallpaper exists"
    else
        echo ":: Wallpaper $wallpaper does not exist. Using default."
        wallpaper=$defaultwallpaper
    fi
else
    echo ":: $cachefile does not exist. Using default wallpaper."
    wallpaper=$defaultwallpaper
fi

# -----------------------------------------------------
# Set wallpaper
# -----------------------------------------------------

echo ":: Setting wallpaper with source image $wallpaper"

# Wait for hyprpaper socket to be ready
timeout=10
while [ $timeout -gt 0 ]; do
    if hyprctl hyprpaper wallpaper ",${wallpaper}" >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
    timeout=$((timeout - 1))
done

# Apply per-monitor and run post-processing (matugen, blur, waybar, etc.)
if [ -f ~/.local/bin/waypaper ]; then
    export PATH=$PATH:~/.local/bin/
fi
~/.config/hypr/scripts/wallpaper.sh "$wallpaper" &
