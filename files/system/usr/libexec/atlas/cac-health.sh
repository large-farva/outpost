#!/bin/bash
set -ouex pipefail

tag="cac-health"

# pcscd.socket enabled?
if systemctl is-enabled pcscd.socket >/dev/null 2>&1; then
  logger -t "$tag" "pcscd.socket: enabled"
else
  logger -t "$tag" "pcscd.socket: NOT enabled"
fi

# DoD trust present?
bundle="/etc/pki/ca-trust/source/anchors/dod-trust-bundle.pem"
if [[ -s "$bundle" ]]; then
  logger -t "$tag" "DoD trust bundle present: $bundle"
else
  logger -t "$tag" "DoD trust bundle MISSING: $bundle"
fi

# p11-kit sees anchors?
if command -v trust >/dev/null 2>&1; then
  count="$(trust list --filter=ca-anchors 2>/dev/null | grep -c '^label:' || true)"
  logger -t "$tag" "p11-kit anchors visible: ${count}"
fi

# OpenSC PKCS#11 library exists?
if [[ -r /usr/lib64/opensc-pkcs11.so ]]; then
  logger -t "$tag" "OpenSC PKCS#11: /usr/lib64/opensc-pkcs11.so OK"
else
  logger -t "$tag" "OpenSC PKCS#11: MISSING"
fi

# Readers currently visible
if command -v opensc-tool >/dev/null 2>&1; then
  readers="$(opensc-tool -l 2>&1 || true)"
  logger -t "$tag" "Readers now: $(echo "$readers" | tr '\n' ' ' | sed 's/  */ /g')"
fi
