# DoD certificates

This directory holds the unmodified [official DoD PKCS#7 bundle](https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip),
`unclass-certificates_pkcs7_DoD.zip`. During the image build, its certificates are
converted to PEM and added to the system trust store.

From this directory, verify it with:

```bash
sha256sum -c unclass-certificates_pkcs7_DoD.zip.sha256
```

When updating the bundle, replace both the archive and checksum here and under
`files/system/usr/share/outpost/certs/`. Keep the official filename. CI checks both
checksums and compares the archives. A matching checksum tells you the stored
copy is intact, not whether it's the latest bundle.

Source: [DoD Cyber Exchange PKI/PKE](https://public.cyber.mil/pki-pke/).
