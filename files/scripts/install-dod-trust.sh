#!/bin/bash
set -ouex pipefail
umask 022

# --- DoD Trust Anchors Installer ---

if [[ -f /etc/atlas/dod.env ]]; then
  # shellcheck source=/dev/null
  . /etc/atlas/dod.env
fi

CERTS_URL="${CERTS_URL:-https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_v5-6_dod.zip}"
CERTS_SHA256="${CERTS_SHA256:-}"

echo "[DoD Trust] Fetching bundle from: $CERTS_URL"
workdir="$(mktemp -d -t dodtrust.XXXXXXXX)"
trap 'rm -rf "$workdir"' EXIT

curl --fail --silent --show-error --location \
     --retry 5 --retry-connrefused --connect-timeout 10 \
     --proto '=https' \
     -o "$workdir/dod-certs.zip" "$CERTS_URL"

if [[ -n "$CERTS_SHA256" ]]; then
  echo "$CERTS_SHA256  $workdir/dod-certs.zip" | sha256sum -c -
fi

command -v unzip >/dev/null || { echo "[DoD Trust] ERROR: 'unzip' not found."; exit 1; }

echo "[DoD Trust] Unzipping bundle..."
unzip -q "$workdir/dod-certs.zip" -d "$workdir/unzipped"

mapfile -t P7B_FILES < <(find "$workdir/unzipped" -type f -iname '*.p7b' || true)

if [[ ${#P7B_FILES[@]} -eq 0 ]]; then
  echo "[DoD Trust] ERROR: No .p7b files found in the provided ZIP."
  exit 1
fi

combined_pem="$workdir/dod-trust-combined.pem"
: > "$combined_pem"

echo "[DoD Trust] Converting PKCS#7 bundles to PEM..."
for p7b in "${P7B_FILES[@]}"; do
  if ! openssl pkcs7 -print_certs -inform DER -in "$p7b" -out "$workdir/tmp.pem" 2>/dev/null; then
    openssl pkcs7 -print_certs -in "$p7b" -out "$workdir/tmp.pem"
  fi
  cat "$workdir/tmp.pem" >> "$combined_pem"
done

if ! grep -q "BEGIN CERTIFICATE" "$combined_pem"; then
  echo "[DoD Trust] ERROR: Conversion produced no PEM certificates."
  exit 1
fi

cert_count="$(grep -c 'BEGIN CERTIFICATE' "$combined_pem" || true)"
echo "[DoD Trust] Certificates extracted: $cert_count"

echo "[DoD Trust] Installing into system trust anchors..."
install -d -m 0755 /etc/pki/ca-trust/source/anchors
install -m 0644 "$combined_pem" /etc/pki/ca-trust/source/anchors/dod-trust-bundle.pem
restorecon -F /etc/pki/ca-trust/source/anchors/dod-trust-bundle.pem || true

echo "[DoD Trust] Updating system trust store..."
update-ca-trust

echo "[DoD Trust] Successfully installed DoD trust anchors."
