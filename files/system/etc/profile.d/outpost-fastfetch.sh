#!/usr/bin/env bash
set -euo pipefail

if command -v fastfetch >/dev/null 2>&1; then
  export FASTFETCH_CONFIG="/usr/share/outpost/fastfetch.jsonc"

  alias fastfetch='command fastfetch -c "$FASTFETCH_CONFIG"'
fi
