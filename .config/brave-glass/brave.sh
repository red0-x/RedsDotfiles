#!/usr/bin/env bash
# Brave with the matugen rice theme + glass new-tab loaded as unpacked extensions.
# (--load-extension re-reads them each launch, so matugen color changes apply on restart.)
exec /usr/bin/brave-browser-stable \
  --load-extension="$HOME/.config/brave-glass-theme,$HOME/.config/brave-glass-newtab" \
  "$@"
