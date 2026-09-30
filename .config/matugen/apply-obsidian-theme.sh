#!/usr/bin/env bash
set -euo pipefail
css="$HOME/.config/matugen/generated/obsidian-glassmind.css"
root="$HOME/Documents/Obsidian Vault"
shopt -s nullglob
for vault in "$root" "$root"/*; do
  appearance="$vault/.obsidian/appearance.json"
  [[ -f "$appearance" ]] || continue
  grep -Eq '"cssTheme"[[:space:]]*:[[:space:]]*"Glassmind"' "$appearance" || continue
  install -D -m 644 "$css" "$vault/.obsidian/themes/Glassmind/theme.css"
  [[ -f "$vault/.obsidian/themes/Glassmind/manifest.json" ]] || printf '{"name":"Glassmind","version":"1.0.0","minAppVersion":"1.0.0","author":"rice"}\n' > "$vault/.obsidian/themes/Glassmind/manifest.json"
done
