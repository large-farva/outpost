#!/usr/bin/env bash
set -ouex pipefail
umask 022

CONFIG_JSON="${1:-{}}"

DEFAULT_URL="https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_v5-6_dod.zip"
DEFAULT_DEST="/etc/pki/ca-trust/source/anchors/dod-trust-bundle.pem"

url="$(echo "$CONFIG_JSON" | jq -r 'try .url // empty')"
dest="$(echo "$CONFIG_JSON" | jq -r 'try .dest // empty')"
force_flag="$(echo "$CONFIG_JSON" | jq -r 'try .force // false')"
sha_cfg="$(echo "$CONFIG_JSON" | jq -r 'try .sha256 // empty')"

: "${url:=$DEFAULT_URL}"
: "${dest:=$DEFAULT_DEST}"

if [[ -f /etc/atlas/dod.env ]]; then
  . /etc/atlas/dod.env
fi

sha="${sha_cfg:-${CERTS_SHA256:-}}"

if [[ "$force_flag" != "true" && -s "$dest" ]]; then
  echo "[dod-trust] Existing bundle at $dest; skipping (force=false)."
  exit 0
fi

workdir="$(mktemp -d -t dodtrust.XXXXXXXX)"
trap 'rm -rf "$workdir"' EXIT

echo "[dod-trust] Fetching: $url"
curl --fail --silent --show-error --location \
     --retry 5 --retry-connrefused --connect-timeout 10 \
     --proto '=https' \
     -o "$workdir/bundle.zip" "$url"

if [[ -n "$sha" ]]; then
  echo "$sha  $workdir/bundle.zip" | sha256sum -c -
fi

if ! unzip -q "$workdir/bundle.zip" -d "$workdir/unzipped" 2>/dev/null; then
  mkdir -p "$workdir/unzipped"
  cp "$workdir/bundle.zip" "$workdir/unzipped/possible.p7b"
fi

mapfile -t P7B_FILES < <(find "$workdir/unzipped" -type f -iname '*.p7b' || true)
if [[ ${#P7B_FILES[@]} -eq 0 ]]; then
  echo "[dod-trust] ERROR: No .p7b files found in the bundle."
  exit 1
fi

combined_pem="$workdir/dod-trust-combined.pem"
: > "$combined_pem"

echo "[dod-trust] Converting PKCS#7 → PEM..."
for p7b in "${P7B_FILES[@]}"; do
  if ! openssl pkcs7 -print_certs -inform DER -in "$p7b" -out "$workdir/tmp.pem" 2>/dev/null; then
    openssl pkcs7 -print_certs -in "$p7b" -out "$workdir/tmp.pem"
  fi
  cat "$workdir/tmp.pem" >> "$combined_pem"
done

if ! grep -q "BEGIN CERTIFICATE" "$combined_pem"; then
  echo "[dod-trust] ERROR: No PEM certificates produced."
  exit 1
fi

cert_count="$(grep -c 'BEGIN CERTIFICATE' "$combined_pem" || true)"
echo "[dod-trust] Certificates extracted: $cert_count"

echo "[dod-trust] Installing to $dest"
install -d -m 0755 "$(dirname "$dest")"
install -m 0644 "$combined_pem" "$dest"
restorecon -F "$dest" 2>/dev/null || true

echo "[dod-trust] Updating system trust store (p11-kit)"
update-ca-trust

echo "[dod-trust] Done."
