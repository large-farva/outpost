# Outpost DoD Certificate Bundle (Vendored)

This directory contains the DoD PKI CA certificate bundle used by Outpost to enable CAC/PIV browsing out of the box.

## Files

- `unclass-certificates_pkcs7_DoD.zip` — downloaded **as-is** from the official DoD Cyber Exchange distribution link
- `unclass-certificates_pkcs7_DoD.zip.sha256` — SHA-256 checksum for the ZIP (for `sha256sum -c`)

## Official sources

- DoD Cyber Exchange (PKI/PKE landing): https://public.cyber.mil/pki-pke/
- Direct download (unclassified PKCS#7 bundle):  
  https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip

#### Additional official distribution references:
- DoD PKI/PKE “Getting Started” area (end-user guidance): https://public.cyber.mil/pki-pke/end-users/getting-started/
- DISA PKE distribution page also references PKCS#7 bundle ZIPs: https://crl.gds.disa.mil/pke

## Verify the ZIP locally

From this directory:

```sh
sha256sum -c unclass-certificates_pkcs7_DoD.zip.sha256
