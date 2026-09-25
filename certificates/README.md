# DoD certificate bundle

Outpost uses this DoD PKI certificate archive for CAC and PIV authentication.
The ZIP is stored with its official filename and contents unchanged.

- `unclass-certificates_pkcs7_DoD.zip` contains the PKCS#7 certificate bundle.
- `unclass-certificates_pkcs7_DoD.zip.sha256` contains the checksum used by
  `sha256sum -c`.

## Sources

The archive comes from the [DoD Cyber Exchange](https://public.cyber.mil/pki-pke/):

- [Download the unclassified PKCS#7 bundle](https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip)
- [PKI/PKE getting-started guide](https://public.cyber.mil/pki-pke/end-users/getting-started/)
- [DISA PKE distribution page](https://crl.gds.disa.mil/pke)

## Verify the archive

Run this command from the `certificates` directory:

``` sh
sha256sum -c unclass-certificates_pkcs7_DoD.zip.sha256
```

The image build uses a second copy under `files/system/usr/share/outpost/certs/`.
When updating the bundle, update both copies and their checksums together. Keep
the official ZIP filename. CI verifies both checksums and compares the archives.
