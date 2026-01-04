#!/bin/bash
set -ouex pipefail
umask 022

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

if [[ -f /etc/outpost/dod.env ]]; then
  # shellcheck source=/dev/null
  . /etc/outpost/dod.env
fi

CERTS_URL="https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip"
CERTS_SHA256="${CERTS_SHA256:-}"

workdir="$(mktemp -d -t dodtrust.XXXXXXXX)" || die "Failed to create temp dir"
trap 'rm -rf "$workdir"' EXIT

curl --fail --silent --show-error --location \
     --retry 5 --retry-connrefused --connect-timeout 10 \
     --proto '=https' \
     -o "$workdir/dod-certs.zip" "$CERTS_URL" \
     || die "Failed to download DoD cert bundle"

[[ -s "$workdir/dod-certs.zip" ]] || die "Downloaded DoD cert bundle is empty"

if [[ -n "$CERTS_SHA256" ]]; then
  printf '%s  %s\n' "$CERTS_SHA256" "$workdir/dod-certs.zip" \
    | sha256sum -c - >/dev/null \
    || die "SHA256 verification failed"
fi

command -v unzip >/dev/null || die "'unzip' not found"
unzip -q "$workdir/dod-certs.zip" -d "$workdir/unzipped" || die "Failed to unzip DoD cert bundle"

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
