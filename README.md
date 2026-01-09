<p align="center">
  <img src="assets/outpost-logo.svg" alt="Outpost logo" width="300" />
</p>

<p align="center">
  <img src="https://github.com/large-farva/outpost/actions/workflows/build.yml/badge.svg">
</p>

# Outpost

### ⚠️ Work in progress!

Outpost is a custom **Universal Blue Aurora–based** immutable desktop image built with **BlueBuild**.  
It extends the `ublue-os/aurora` base image and provides a **CAC-ready Fedora workstation** with curated defaults and zero post-install configuration.

Outpost is designed for environments where **Common Access Card (CAC)** authentication and secure DoD network access are required.

## Features

### DoD CAC support out of the box
- `opensc`, `pcsc-lite`,`pcsc-tools`, `pcsc-lite-ccid`, `p11-kit`
- `pcscd.socket` enabled for automatic activation

Outpost does not ship CACKey, CoolKey, or proprietary vendor middleware. OpenSC is the supported and tested provider.

### DoD trust anchors (vendored, auditable)
- Official **DoD PKCS#7 certificate bundle** is **vendored in the repository**
- ZIP filename is unchanged from the official distribution
- Certificates are extracted, converted to PEM, and installed into the system trust store at build time

### Firefox (RPM)
- **Firefox** is installed as an **RPM**, not Flatpak
- Uses NSS with full system PKCS#11 and CA trust integration

### Curated Flatpak baseline
- Kontainer
- OnlyOffice
- Signal
- XCA

## Installation

⚠️ You must rebase from Aurora, Kinoite, or a Kinoite-based image! Aurora is recommended.

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
- Used by NSS-based applications such as Firefox and eventually Okular

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

- **Firefox (RPM)**: supported with CAC
- **Flatpak browsers**: not currently supported

## Troubleshooting

### To verify CAC and Flatpak readiness

```bash
cac-check
```

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

### Firefox not prompting for CAC

In Firefox:

Settings > Privacy & Security > Certificates > Security Devices
If required, load the OpenSC module manually:

```
/usr/lib64/opensc-pkcs11.so
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
- Getting Firefox to work with CAC without manual intervention

### Longer-term
- Okular support for CAC PDF signing

## Issues

If you encounter problems, open an issue and include:

```bash
journalctl -u pcscd.socket
opensc-tool -l
```

This helps diagnose reader detection, USB enumeration, and middleware issues.