#!/usr/bin/env bash
# Toggle fcitx5 between US keyboard and Chinese Pinyin
fcitx5-remote -t
pkill -RTMIN+8 waybar
