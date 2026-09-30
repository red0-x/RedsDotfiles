#!/usr/bin/env bash
# CPU governor / boost widget for waybar.
#   (no args)  -> emit JSON status
#   toggle     -> flip performance <-> powersave (and boost with it)
# Persists the choice to /etc/cpupower-service.conf so it survives reboot.

CPUDIR=/sys/devices/system/cpu
CONF=/etc/cpupower-service.conf

gov=$(cat "$CPUDIR/cpu0/cpufreq/scaling_governor" 2>/dev/null || echo unknown)
boost=$(cat "$CPUDIR/cpufreq/boost" 2>/dev/null || echo 0)

max_mhz() {
    local m=0 f
    for f in "$CPUDIR"/cpu*/cpufreq/scaling_cur_freq; do
        read -r v < "$f" 2>/dev/null || continue
        (( v > m )) && m=$v
    done
    echo $(( m / 1000 ))
}

case "$1" in
toggle)
    if [[ $gov == performance ]]; then
        new_gov=powersave; new_boost=0
    else
        new_gov=performance; new_boost=1
    fi
    pkexec /usr/local/bin/cpu-governor-apply "$new_gov" "$new_boost"
    pkill -RTMIN+9 waybar
    exit 0
    ;;
esac

mhz=$(max_mhz)

if [[ $gov == performance ]]; then
    icon=""; class=performance
else
    icon=""; class=powersave
fi

[[ $boost == 1 ]] && bstate="on" || bstate="off"

printf '{"text":"%s %s","class":"%s","tooltip":"Governor: %s\\nBoost: %s\\nPeak core: %s MHz\\nClick to toggle"}\n' \
    "$icon" "$gov" "$class" "$gov" "$bstate" "$mhz"
