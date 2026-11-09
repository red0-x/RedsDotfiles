# Rice dynamic island (quickshell)

One pill over the bar centre that morphs into a card. Colours come from
`~/.config/waybar/rice-palette.css`, so a wallpaper change recolours it too.

    qs ipc -c island call island open music|updates|wifi|bt|hub
    qs ipc -c island call island close
    qs ipc -c island call island isopen      # true/false
    qs ipc -c island call island debug       # state + pointer/hover, for diagnosing

* **Super+Q** closes an open island first, otherwise behaves as killactive
  (`~/.config/hypr/scripts/island-or-kill.sh`).
* Bar chips: updates / network / bluetooth open their island.
  Right-click keeps the old tools.
* The Discord chip opens the inbox card. While Slack is running it also shows
  Slack rows (from desktop notifications, with an "Slack is open" fallback);
  double-click or Enter focuses Slack rather than Discord. The chip becomes a
  Slack glyph when Slack is open and Discord has no presence or unread.
* Hover the pill: music card (cover or live browser video, seek, prev/play/next,
  heart, open-player). Heart sends Spotify's own Alt+Shift+B to the exact
  Spotify window address; it is optimistic (MPRIS exposes no liked state) and
  does nothing when no Spotify window exists. Open-player focuses that window,
  which also switches to its workspace.
* Updates: real dnf + flatpak lists, then a determinate line for the overall run
  and one for the current download. The run is detached and logged to
  `~/.cache/rice-update-*.log`, so restarting the shell does not lose it.
* Wi-Fi: scanning only while the card is up; secured networks ask for the
  passphrase inline.
* Bluetooth: adapter toggle, scan, pair/connect/disconnect.

## Known limits

* Qt does not deliver hover events to this layer surface under Hyprland
  (clicks work), so hover is a 150 ms `hyprctl cursorpos` poll. Do not remove it.
* Live video needs an MPRIS player whose track title also appears in a window
  title (e.g. a browser with MPRIS enabled). Spotify shows cover art only.
* `cava.conf` here is separate from `~/.config/cava/config` on purpose: raw
  values for the widget, not the terminal bars.
