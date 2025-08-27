#!/usr/bin/env bash
set -euo pipefail

# --- DoD Trust Anchors Installer ---
CERTS_URL="${CERTS_URL:-https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_v5-6_dod.zip}"

echo "[DoD Trust] Fetching bundle from: $CERTS_URL"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

curl -fsSL "$CERTS_URL" -o "$workdir/dod-certs.zip"

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
  if openssl pkcs7 -print_certs -inform DER -in "$p7b" -out "$workdir/tmp.pem" 2>/dev/null; then
    cat "$workdir/tmp.pem" >> "$combined_pem"
  else
    openssl pkcs7 -print_certs -in "$p7b" -out "$workdir/tmp.pem"
    cat "$workdir/tmp.pem" >> "$combined_pem"
  fi
done

if ! grep -q "BEGIN CERTIFICATE" "$combined_pem"; then
  echo "[DoD Trust] ERROR: Conversion produced no PEM certificates."
  exit 1
fi

echo "[DoD Trust] Installing into system trust anchors..."
install -d /etc/pki/ca-trust/source/anchors
cp "$combined_pem" /etc/pki/ca-trust/source/anchors/dod-trust-bundle.pem

echo "[DoD Trust] Updating system trust store..."
update-ca-trust

echo "[DoD Trust] Successfully installed DoD trust anchors."
