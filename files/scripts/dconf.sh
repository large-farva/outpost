#!/bin/bash
set -ouex pipefail

if [[ -d /etc/dconf/db/local.d ]]; then
  echo "[atlas] Compiling dconf defaults..."
  dconf update || true
fi
