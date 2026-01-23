#!/usr/bin/env sh

case "$-" in
  *i*) ;;
  *) return 0 2>/dev/null || exit 0 ;;
esac
[ -n "${SSH_TTY:-}" ] || [ -n "${TERM:-}" ] || return 0 2>/dev/null || exit 0

STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/outpost"
DISABLE_FILE="${STATE_DIR}/disable-motd"

if [ -e "$DISABLE_FILE" ]; then
  return 0 2>/dev/null || exit 0
fi
if command -v run-parts >/dev/null 2>&1 && [ -d /usr/lib/motd.d ]; then
  run-parts /usr/lib/motd.d 2>/dev/null || true
fi
