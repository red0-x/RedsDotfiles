#!/usr/bin/env bash
# Launch Slack with a localhost-only DevTools port (the injector runs as the slack-glass user service).
exec flatpak run com.slack.Slack --remote-debugging-port=9229 --remote-debugging-address=127.0.0.1 "$@"
