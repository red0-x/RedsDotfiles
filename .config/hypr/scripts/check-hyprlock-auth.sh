#!/usr/bin/env bash
# Run without locking the desktop or submitting any authentication attempts.
set -euo pipefail
config="${1:-$HOME/.config/hypr/hyprlock.conf}"
grep -Eq '^\s*pam:enabled\s*=\s*true\s*$' "$config"
grep -Eq '^\s*pam:module\s*=\s*password-auth\s*$' "$config"
grep -Eq '^\s*fingerprint:enabled\s*=\s*true\s*$' "$config"
grep -Eq '^auth\s+sufficient\s+pam_unix\.so' /etc/pam.d/password-auth
if grep -Eq '^auth.*(pam_fprintd|include|substack)' /etc/pam.d/password-auth; then exit 1; fi
# /dev/null cannot be a Wayland socket. Hyprlock parses config before connecting.
ulimit -c 0
output=$(env -u WAYLAND_SOCKET hyprlock --config "$config" --display /dev/null --verbose 2>&1) || true
if grep -q 'Config.*error' <<< "$output"; then printf '%s\n' "$output"; exit 1; fi
grep -q "Couldn't connect to a wayland compositor" <<< "$output"
printf '%s\n' 'PASS: configuration parses, password PAM is independent, parallel fingerprint auth is enabled.'
