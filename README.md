[![bluebuild build badge](https://github.com/large-farva/outpost/actions/workflows/build.yml/badge.svg)](https://github.com/large-farva/outpost/actions/workflows/build.yml)

<p align="center">
  <img src="assets/outpost-logo.svg" alt="Outpost logo" width="200" />
</p>

# Outpost

Outpost is a custom **Fedora Kinoite–based** immutable desktop image built with **BlueBuild**.  
It extends the `ublue-os/kinoite-main` base image and provides a **CAC-ready Fedora workstation** with curated defaults and zero post-install configuration.

Outpost is designed for environments where **Common Access Card (CAC)** authentication and secure DoD network access are required.

## Features

### DoD CAC support out of the box
- `pcsc-lite`, `pcsc-lite-ccid`, `opensc`, `p11-kit`, `pcsc-tools`
- `pcscd.socket` enabled for automatic activation
- `p11-kit-server.socket` enabled for Flatpak PKCS#11 access

### DoD trust anchors (vendored, auditable)
- Official **DoD PKCS#7 certificate bundle** is **vendored in the repository**
- ZIP filename is unchanged from the official distribution
- Certificates are extracted, converted to PEM, and installed into the system trust store at build time
- No network access required during image builds

### Chromium Flatpak CAC support
- **Chromium Flatpak** is supported via PKCS#11 socket passthrough
- Targeted Flatpak override exposes the `p11-kit` socket only to Chromium
- No global sandbox weakening

### Curated Flatpak baseline
- Chromium
- Flatseal
- Warehouse
- OnlyOffice
- Signal
- Kontainer
- Bazaar (package manager)

## Installation

⚠️ You must rebase from Kinoite or a Kinoite-based image!

### 1. Bootstrap (unsigned image)
```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/large-farva/outpost:latest
sudo systemctl reboot
```

### 2. Rebase to the signed image
```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/large-farva/outpost:latest
sudo systemctl reboot
```

## Verification

Outpost images are signed using **Sigstore Cosign**.

Verify with the included public key:

```bash
cosign verify --key cosign.pub ghcr.io/large-farva/outpost:latest
```

## CAC Usage

Outpost includes all middleware and trust components required for CAC authentication.

### Smart Card Middleware

- `pcsc-lite` / `pcsc-lite-ccid` provide the PC/SC service and CCID driver
- `pcscd.socket` is enabled for automatic activation
- `pcsc-tools` for inspection and debugging (`pcsc_scan`)

### PKCS#11 Provider

- `opensc` supplies the `opensc-pkcs11.so` module
- Used by NSS-based applications and Chromium via `p11-kit`

### System Trust Store

- DoD PKCS#7 bundle is vendored in:

  ```
  /usr/share/outpost/certs/
  ```
- Certificates are installed into:

  ```
  /etc/pki/ca-trust/source/anchors/
  ```
- `update-ca-trust` is executed during build

### Browser Support

- **Chromium (Flatpak)**: supported with CAC
- **Other Flatpak browsers**: not currentlysupported

⚠️ *Outpost does not ship CACKey, CoolKey, or proprietary vendor middleware. OpenSC is the supported and tested provider.*

## Troubleshooting

### Reader Not Detected

```bash
pcsc_scan
systemctl status pcscd.socket
```

### OpenSC Not Listing the Reader

```bash
opensc-tool -l
```

### DoD Sites Not Trusted

```bash
trust list | grep DoD
sudo update-ca-trust
```

### Chromium not seeing the CAC

- Verify the Flatpak override exists:
```
/etc/flatpak/overrides/org.chromium.Chromium
```

- Confirm the PKCS#11 socket:
```bash
systemctl --user status p11-kit-server.socket
```

### PC/SC Logs

```bash
journalctl -u pcscd.socket
```

### USB / reader hardware logs

```bash
journalctl -k | grep -i usb
```

## Roadmap

### Near-term
- Okular groundwork for PDF signing with CAC

### Longer-term
- Optional hardened / enterprise configuration profile
- TPM-backed trust integration (future Fedora work)

## Issues

If you encounter problems, open an issue and include:

```bash
journalctl -u pcscd.socket
opensc-tool -l
```

This helps diagnose reader detection, USB enumeration, and middleware issues.