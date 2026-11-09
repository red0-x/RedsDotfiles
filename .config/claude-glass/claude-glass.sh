#!/usr/bin/env bash
# Launch the user-owned Claude copy with a localhost-only DevTools port for the
# rice glass CSS injector (claude-glass.service). The packaged /usr/lib binary
# refuses debugging switches, so this copy carries a small guard bypass.
# Skip the port on a second launch: the first instance already owns it, and a
# duplicate debug bind prints a devtools error before the single-instance focus.
port_args=()
if ! ss -ltn 2>/dev/null | grep -q '127\.0\.0\.1:9232'; then
  port_args=(--remote-debugging-port=9232 --remote-debugging-address=127.0.0.1)
fi
exec "$HOME/.local/share/claude-desktop/claude-desktop" "${port_args[@]}" "$@"
