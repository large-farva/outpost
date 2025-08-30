#!/bin/bash
set -ouex pipefail

mkdir -p "$HOME/.config/atlas"
mkdir -p "$HOME/.pki/nssdb"

NSSDB="sql:$HOME/.pki/nssdb"

if ! command -v modutil >/dev/null 2>&1; then
  echo "[atlas-nss] nss-tools not found; cannot register OpenSC now."
  exit 0
fi

if ! modutil -list -dbdir "$NSSDB" | grep -q 'OpenSC PKCS#11 Module'; then
  modutil -add "OpenSC PKCS#11 Module" \
          -libfile /usr/lib64/opensc-pkcs11.so \
          -dbdir "$NSSDB" -force
fi

touch "$HOME/.config/atlas/.nss-opensc-done"

echo "[atlas-nss] OpenSC PKCS#11 is ready in $NSSDB"
