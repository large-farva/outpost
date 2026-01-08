#!/bin/bash
set -ouex pipefail

mkdir -p "$HOME/.config/outpost" "$HOME/.pki/nssdb"

NSSDB="sql:$HOME/.pki/nssdb"

if ! command -v modutil >/dev/null 2>&1; then
  echo "[outpost-nss] nss-tools not found; cannot register OpenSC now."
  exit 0
fi

if ! modutil -list -dbdir "$NSSDB" | grep -q 'OpenSC PKCS#11 Module'; then
  modutil -add "OpenSC PKCS#11 Module" \
          -libfile /usr/lib64/opensc-pkcs11.so \
          -dbdir "$NSSDB" -force
fi

touch "$HOME/.config/outpost/.nss-opensc-done"
echo "[outpost-nss] OpenSC PKCS#11 is ready in $NSSDB"
