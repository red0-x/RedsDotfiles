#!/usr/bin/env bash
# fcitx5-remote: 2 = IM active (pinyin), else English
if [ "$(fcitx5-remote 2>/dev/null)" = "2" ]; then
    echo "中"
else
    echo "EN"
fi
