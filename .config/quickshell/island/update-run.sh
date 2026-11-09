#!/usr/bin/env bash
# Runs the queued updates, writing a parseable log the island tails.
#   update-run.sh LOGFILE      (queue in ~/.cache/rice-update.{flat,dnf})
log="$1"
mkdir -p "$(dirname "$log")"
exec >"$log" 2>&1
mapfile -t flat < "$HOME/.cache/rice-update.flat" 2>/dev/null
mapfile -t dnf < "$HOME/.cache/rice-update.dnf" 2>/dev/null
echo "@@TOTAL ${#flat[@]} ${#dnf[@]}"
rc=0
if [ "${#flat[@]}" -gt 0 ]; then
    echo "@@PHASE flatpak"
    flatpak update -y --noninteractive || rc=$?
fi
if [ "$rc" -eq 0 ] && [ "${#dnf[@]}" -gt 0 ]; then
    echo "@@PHASE dnf"
    pkexec dnf upgrade -y --refresh || rc=$?
fi
echo "@@EXIT $rc"
