# DoD certificates

The unmodified [official DoD PKCS#7 bundle](https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip)
is stored as `unclass-certificates_pkcs7_DoD.zip`. The image build converts its
certificates to PEM and installs them in the system trust store.

From this directory, verify it with:

```bash
sha256sum -c unclass-certificates_pkcs7_DoD.zip.sha256
```

When updating the bundle, replace both the archive and checksum here and under
`files/system/usr/share/outpost/certs/`. Keep the official filename. CI checks both
checksums and compares the archives. A matching checksum verifies the stored
copy; it does not establish that the bundle is current.

Source: [DoD Cyber Exchange PKI/PKE](https://public.cyber.mil/pki-pke/).
