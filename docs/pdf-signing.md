# Sign a PDF with a CAC

Use the RPM version of Okular included with Outpost. Have the reader connected,
the card inserted, and a copy of the PDF available. Signing requires a suitable
certificate on the card and its PIN.

## Set up Okular

Close Okular, then choose **PDF signing setup** in Outpost or run:

```bash
cac-pdf-setup
```

Run this as your desktop user, without sudo. Setup checks the shared certificate
database and selects it for Okular without changing existing certificates. If Okular
already uses a different certificate store, setup asks before replacing that choice.
You can decline the change and keep your current setting.

When settings change, the helper prints the path of a backup beside
`~/.config/okular-generator-popplerrc` (or in `XDG_CONFIG_HOME` if customized).
Keep that backup if you may want to restore the previous choice. Close Okular
before restoring its configuration file.

## Sign and save

1. Open the PDF in Okular.
2. Choose **Tools > Digitally Sign** and draw the signature rectangle, or use an
   existing signature field in the document.
3. Select the CAC's signing certificate, not its encryption certificate.
4. Enter the PIN in Okular when prompted.
5. Save a new signed copy so the original remains available.
6. Open the saved copy and inspect its **Signatures** panel. Check the signature
   details and certificate, including any trust or revocation warnings.

A visible signature rectangle alone does not mean the digital signature is valid.
Follow the recipient's requirements for the document and certificate.
See [KDE's signing guide](https://docs.kde.org/trunk_kf6/en/okular/okular/signatures.html)
for Okular's signing and verification features.

## If signing fails

- **No certificate listed:** run `cac-check`, confirm that the card is detected,
  and check the Okular certificate-store result. Close Okular before rerunning
  setup. Reopen it afterward.
- **Card disappears:** close Okular and Firefox, then run `cac-recover`. Reinsert
  the card when prompted and reopen the document.
- **PIN prompt canceled:** signing does not complete. Retry when you're ready.
  The setup helper cannot supply the PIN for you.
- **PIN rejected:** stop repeated attempts and contact card support. The helpers
  do not unlock cards or reset PINs.
- **Signature has a warning:** read the verification details. A signing operation
  and a trusted, valid signature are separate checks. Do not disable verification
  to hide the warning.

The setup has passed container checks, and a user has reported successfully signing
with a physical CAC in Okular on the testing branch. See the
[validation notes](../CONTRIBUTING.md#validation-status) for scope and limitations.
[CAC troubleshooting](cac.md) explains how to save a local report. Reports and
helpers never request your PIN.
