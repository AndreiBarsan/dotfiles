#!/usr/bin/env bash
# Ensures exactly one managed powerline install: a pipx venv (see system/env.zsh).
# Idempotent: safe to re-run. macOS keeps the legacy `pip install --user` layout.

set -eu

info() { echo "  [..] $1"; }
ok()   { echo "  [OK] $1"; }
die()  { echo "  [FAIL] $1" >&2; exit 1; }

OS="$(uname -s)"
if [[ "$OS" == 'Darwin' ]]; then
  echo "macOS: legacy layout — keep \`pip3 install --user powerline-status\` in place (see system/env.zsh)."
  exit 0
fi
if [[ "$OS" != 'Linux' ]]; then
  die "Unsupported platform: $OS"
fi

conf_glob() { ls "$HOME"/.local/share/pipx/venvs/powerline-status/lib/python*/site-packages/powerline/bindings/tmux/powerline.conf 2>/dev/null || true; }

if conf="$(conf_glob)" && [[ -n "$conf" ]]; then
  ok "powerline already managed via pipx"
else
  if ! command -v pipx >/dev/null 2>&1; then
    info "pipx not found; installing via user-site pip..."
    python3 -m pip install --user pipx
  fi
  export PATH="$HOME/.local/bin:$PATH"
  info "Installing powerline-status via pipx..."
  pipx install powerline-status
  conf="$(conf_glob)"
  [[ -n "$conf" ]] || die "pipx install finished but no conf found; run: pipx install powerline-status"
  ok "installed powerline-status"
fi

command -v powerline >/dev/null 2>&1 || die "powerline shim missing from PATH (check ~/.local/bin)"

# Exactly one daemon: kill any stale one (e.g. left over from a pip --user install).
# Coarse pgrep filter, then require the daemon's real argv shape; this avoids
# matching shells/agents whose command line merely mentions "powerline-daemon".
for pid in $(pgrep -f 'powerline-daemon' || true); do
  cmdline="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)" || continue
  argv0="${cmdline%% *}"
  case "$argv0" in *python*) ;; *) continue ;; esac      # a daemon is a python entry point
  [[ "$cmdline" == *bin/powerline-daemon* ]] || continue  # ...running the daemon, not a client
  if [[ "$cmdline" != *"$HOME/.local/share/pipx"* ]]; then
    info "killing stale powerline-daemon (pid $pid)"
    kill "$pid" 2>/dev/null || true
  fi
done

# Start the daemon only if it is not running: `powerline-daemon` exits
# non-zero when a daemon is already up (would trip `set -e`), and the client
# (`powerline tmux right`) renders standalone and is NOT a liveness probe.
# The daemon is a long-lived process, so a process check is authoritative.
if ! pgrep -f 'bin/powerline-daemon' >/dev/null 2>&1; then
  info "powerline daemon not running; starting..."
  powerline-daemon -q || true
fi
pgrep -f 'bin/powerline-daemon' >/dev/null 2>&1 || die "powerline daemon not running after start attempt"
ok "daemon: $(pgrep -af 'bin/powerline-daemon' | head -1)"

# Stale legacy copies are noise; report, don't auto-delete.
if ls "$HOME"/.local/lib/python*/site-packages/powerline >/dev/null 2>&1; then
  echo "  [!!] legacy pip --user powerline copies found — safe to delete:" >&2
  ls -d "$HOME"/.local/lib/python*/site-packages/powerline 2>/dev/null
fi

echo "Resolved: TMUX_POWERLINE_CONF=\"$conf\""
