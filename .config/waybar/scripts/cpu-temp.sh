#!/usr/bin/env bash
# CPU temperature widget for waybar.
# Reads k10temp Tctl and reports with warn/crit classes.

HWMON=""
for d in /sys/class/hwmon/hwmon*; do
    [[ $(cat "$d/name" 2>/dev/null) == k10temp ]] && HWMON=$d && break
done

if [[ -z $HWMON ]]; then
    printf '{"text":"T --","class":"unknown","tooltip":"k10temp not found"}\n'
    exit 0
fi

# Tctl is the control temperature AMD boosts against.
temp=0
for l in "$HWMON"/temp*_label; do
    if [[ $(cat "$l" 2>/dev/null) == Tctl ]]; then
        read -r temp < "${l%_label}_input"
        break
    fi
done
[[ $temp == 0 ]] && read -r temp < "$HWMON/temp1_input"
c=$(( temp / 1000 ))

# Peak core clock, for context alongside the governor widget.
m=0
for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
    read -r v < "$f" 2>/dev/null || continue
    (( v > m )) && m=$v
done
mhz=$(( m / 1000 ))

if   (( c >= 90 )); then class=critical
elif (( c >= 80 )); then class=warning
else                     class=normal
fi

guard=$(systemctl is-active cpu-thermal-guard.service 2>/dev/null)
[[ $guard == active ]] && gtxt="on" || gtxt="off"

printf '{"text":" %s°C","class":"%s","tooltip":"CPU: %s°C\\nPeak core: %s MHz\\nThermal guard: %s\\nWarn 80°C · Critical 90°C"}\n' \
    "$c" "$class" "$c" "$mhz" "$gtxt"
