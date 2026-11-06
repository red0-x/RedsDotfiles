#!/usr/bin/env python3
"""Sniff desktop notifications off the session bus and write them for the
quickshell toast overlay. Works alongside swaync: dbus-monitor observes the
Notify call, so this still fires when swaync's DND would swallow the popup.

Out: ~/.cache/rice-toasts.json  {"ts": ms, "toasts": [{id, app, summary, body}]}
"""
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

OUT = Path.home() / ".cache" / "rice-toasts.json"
APP = Path.home() / ".local" / "bin" / "rice-toast"
MAX_KEEP = 30

ESCAPES = {"n": "\n", "t": "\t", '"': '"', "\\": "\\"}


def unescape(s: str) -> str:
    out, i = [], 0
    while i < len(s):
        c = s[i]
        if c == "\\" and i + 1 < len(s):
            out.append(ESCAPES.get(s[i + 1], s[i + 1]))
            i += 2
        else:
            out.append(c)
            i += 1
    return "".join(out)


def load() -> list:
    try:
        return json.loads(OUT.read_text()).get("toasts", [])
    except Exception:
        return []


def push(app: str, summary: str, body: str) -> None:
    app, summary, body = (app or "").strip(), (summary or "").strip(), (body or "").strip()
    if not summary and not body:
        return
    if not app:
        app = "Notification"
    toasts = load()
    now = int(time.time() * 1000)
    # apps re-send the same notification (replaces_id); do not double-toast
    if toasts:
        last = toasts[-1]
        if (last.get("app") == app and last.get("summary") == summary
                and last.get("body") == body and now - last.get("ts", 0) < 4000):
            return
    toasts.append({"ts": now, "app": app, "summary": summary, "body": body})
    toasts = toasts[-MAX_KEEP:]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    tmp = OUT.with_suffix(".tmp")
    tmp.write_text(json.dumps({"ts": now, "toasts": toasts}))
    os.replace(tmp, OUT)


def main() -> None:
    proc = subprocess.Popen(
        ["dbus-monitor", "--session",
         "interface='org.freedesktop.Notifications',member='Notify'"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1,
    )
    strings, armed = [], False
    try:
        for line in proc.stdout:
            line = line.rstrip("\n")
            if "member=Notify" in line:
                armed, strings = True, []
                continue
            if not armed:
                continue
            m = re.match(r'\s+string "(.*)"$', line)
            if m:
                strings.append(unescape(m.group(1)))
                if len(strings) >= 4:
                    app, _icon, summary, body = strings[:4]
                    push(app, summary, body)
                    armed = False
            elif line.startswith("method call") or line.startswith("signal"):
                armed = False
    finally:
        proc.terminate()


if __name__ == "__main__":
    main()
