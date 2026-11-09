#!/usr/bin/env bash
# Waybar module: Discord presence + unread. Icon-only chip; the name, elapsed
# time and inbox preview live in the tooltip and the quickshell discord card.
# Fed by the RpcBridge BetterDiscord plugin (~/.cache/discord-{rpc,inbox}.json,
# both stamped with ts; stale = Discord quit).
# Click opens the island card, right click focuses Discord.
set -u
rpc="$HOME/.cache/discord-rpc.json"
inbox="$HOME/.cache/discord-inbox.json"
now=$(date +%s%3N)

rpc_ok=0
if [[ -r $rpc ]] && (( now - $(jq -r '.ts // 0' "$rpc" 2>/dev/null || echo 0) < 10000 )); then rpc_ok=1; fi
inbox_ok=0
if [[ -r $inbox ]] && (( now - $(jq -r '.ts // 0' "$inbox" 2>/dev/null || echo 0) < 15000 )); then inbox_ok=1; fi

slack_open=0
if pgrep -f 'com.slack.Slack|/app/extra/slack' >/dev/null 2>&1; then slack_open=1; fi
(( rpc_ok == 0 && inbox_ok == 0 && slack_open == 0 )) && exit 0

unread=0
[[ $inbox_ok == 1 ]] && unread=$(jq -r '[.channels[]? | (.unread // 0)] | add // 0' "$inbox" 2>/dev/null || echo 0)

tip=""
if [[ $inbox_ok == 1 ]]; then
  tip=$(jq -r '[.channels[]? | (if .mentions > 0 then "● " else "· " end) + .name
                + (if .guild != "" then "  (" + .guild + ")" else "" end)] | .[0:5] | join("\n")' "$inbox" 2>/dev/null || true)
fi

if [[ $rpc_ok == 1 ]]; then
  jq -c --argjson unread "$unread" --arg tip "$tip" '
    def dur($s): ($s / 3600 | floor) as $h | (($s % 3600) / 60 | floor) as $m
      | if $h > 0 then "\($h)h \($m)m" else "\($m)m" end;
    ((now - (.start / 1000)) | if . > 0 then dur(.) else "" end) as $el
    | {
        text: "\uf392",
        class: (if .type == 0 then "playing" elif .type == 1 then "streaming" elif .type == 2 then "listening" elif .type == 3 then "watching" else "competing" end),
        tooltip: (([.name,
                    (if .details != "" then .details else empty end),
                    (if .state != "" then .state else empty end),
                    (if $el != "" then "for \($el)" else empty end)]
                  | join("\n"))
                  + (if $unread > 0 then "\n\n" + ($unread | tostring) + " unread\n" + $tip else "" end)
                  | gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;"))
      }' "$rpc"
elif (( unread > 0 )); then
  jq -nc --argjson unread "$unread" --arg tip "$tip" '{
    text: "\uf392",
    class: "unread",
    tooltip: ((($unread | tostring) + " unread\n" + $tip) | gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;"))
  }'
elif (( slack_open == 1 )); then
  printf '{"text":"\\uf198","class":"slack","tooltip":"Slack is open"}'
fi
