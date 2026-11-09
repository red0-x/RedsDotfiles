#!/usr/bin/env bash
# Launch Slack with a localhost-only DevTools port (the injector runs as the slack-glass user service).
# Slack refuses --remote-debugging-port against its default profile, so run out
# of a copy of it (same login/workspaces, caches excluded).
PROFILE="$HOME/.var/app/com.slack.Slack/config/slack-glass-profile"
exec flatpak run com.slack.Slack --user-data-dir="$PROFILE" --remote-debugging-port=9229 --remote-debugging-address=127.0.0.1 "$@"
