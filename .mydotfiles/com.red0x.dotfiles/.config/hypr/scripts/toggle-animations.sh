#!/usr/bin/env bash
cache_file="$HOME/.cache/toggle_animation"
if [[ $(cat $HOME/.config/hypr/conf/animation.conf) == *"disabled"* ]]; then
    echo ":: Toggle blocked by disabled.conf variation."
else
    if [ -f $cache_file ]; then
        hyprctl eval 'hl.config({ animations = { enabled = true } })'
        rm $cache_file
    else
        hyprctl eval 'hl.config({ animations = { enabled = false } })'
        touch $cache_file
    fi
fi
