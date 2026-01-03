#!/bin/bash
set -ouex pipefail

if [[ -d /etc/dconf/db/local.d ]]; then
  echo "[outpost] Compiling dconf defaults..."
  dconf update || true
fi
