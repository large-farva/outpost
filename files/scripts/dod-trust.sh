#!/bin/bash
set -ouex pipefail
umask 022

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

CERTS_DIR="/usr/share/outpost/certs"
CERTS_ZIP="${CERTS_DIR}/unclass-certificates_pkcs7_DoD.zip"
CERTS_SHA256_FILE="${CERTS_DIR}/unclass-certificates_pkcs7_DoD.zip.sha256"

[[ -s "$CERTS_ZIP" ]] || die "DoD cert ZIP not found or empty: $CERTS_ZIP"

if [[ -s "$CERTS_SHA256_FILE" ]]; then
  (
    cd "$CERTS_DIR"
    sha256sum -c "$(basename "$CERTS_SHA256_FILE")" >/dev/null
  ) || die "SHA256 verification failed for vendored DoD cert ZIP"
fi

command -v unzip >/dev/null || die "'unzip' not found"

workdir="$(mktemp -d -t dodtrust.XXXXXXXX)" || die "Failed to create temp dir"
trap 'rm -rf "$workdir"' EXIT

unzip -q "$CERTS_ZIP" -d "$workdir/unzipped" || die "Failed to unzip DoD cert bundle"

mapfile -t P7B_FILES < <(find "$workdir/unzipped" -type f -iname '*.p7b' || true)
[[ ${#P7B_FILES[@]} -gt 0 ]] || die "No .p7b files found in DoD bundle"

combined_pem="$workdir/dod-trust-combined.pem"
: > "$combined_pem"

for p7b in "${P7B_FILES[@]}"; do
  if ! openssl pkcs7 -print_certs -inform DER -in "$p7b" -out "$workdir/tmp.pem" 2>/dev/null; then
    openssl pkcs7 -print_certs -in "$p7b" -out "$workdir/tmp.pem" \
      || die "OpenSSL PKCS#7 conversion failed"
  fi
  cat "$workdir/tmp.pem" >> "$combined_pem"
done

grep -q "BEGIN CERTIFICATE" "$combined_pem" || die "No PEM certificates produced"

install -d -m 0755 /etc/pki/ca-trust/source/anchors || die "Failed to create anchors dir"
install -m 0644 "$combined_pem" /etc/pki/ca-trust/source/anchors/dod-trust-bundle.pem \
  || die "Failed to install trust bundle"

restorecon -F /etc/pki/ca-trust/source/anchors/dod-trust-bundle.pem >/dev/null 2>&1 || true
update-ca-trust || die "update-ca-trust failed"
