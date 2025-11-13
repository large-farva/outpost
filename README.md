<p align="center">
  <img src="assets/outpost-logo.svg" alt="Outpost logo" width="200" />
</p>

# Outpost

[![bluebuild build badge](https://github.com/large-farva/outpost/actions/workflows/build.yml/badge.svg)](https://github.com/large-farva/outpost/actions/workflows/build.yml)

Outpost is a custom Fedora Silverblue–based image built with **BlueBuild**.  
It extends the [`ublue-os/silverblue-main`](https://github.com/ublue-os) base image and provides a CAC-ready Fedora workstation with curated defaults and zero post-install configuration.

Outpost is built for environments where **Common Access Card (CAC)** authentication and secure DoD network access are required.

## Features

- **DoD CAC support out of the box**  
  - `pcsc-lite`, `pcsc-lite-ccid`, `opensc`, `p11-kit`, `pcsc-tools`
  - `pcscd.socket` enabled for automatic activation

- **DoD trust anchors installed at build time**  
  - DISA’s PKI bundle is fetched, verified, converted, and added to the system CA store

- **RPM Firefox for full PKCS#11 + NSS support**  
  Flatpak browsers do not support PKCS#11 modules due to sandboxing.

- **Curated Flatpak baseline**  
  Loupe, Papers, Clapper, Inspector, Signal, Extension Manager, Bottles, OnlyOffice, Warehouse, BlackBox, and more

- **Streamlined Fedora desktop**  
  Some optional packages, GNOME extras, and non-English font families removed

## Installation

1. First rebase to the **unsigned** image to bootstrap the signing policy:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/large-farva/outpost:latest
sudo systemctl reboot
````

2. After reboot, rebase to the **signed** image:

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

* `pcsc-lite` / `pcsc-lite-ccid` provide the PC/SC service and CCID driver
* `pcscd.socket` is enabled for automatic activation
* `pcsc-tools` for inspection and debugging (`pcsc_scan`)

### PKCS#11 Provider

* `opensc` supplies the `opensc-pkcs11.so` module used by Firefox and other NSS apps

### System Trust Store

* DISA’s DoD PKCS#7 bundle is downloaded at build time
* Certificates are extracted, converted to PEM, and installed into:

  ```
  /etc/pki/ca-trust/source/anchors/
  ```
* `update-ca-trust` is executed during build

### Browser Support

* **Firefox (RPM)** works out of the box with CAC
* **Flatpak browsers are not supported**
* **Chrome / Chromium CAC support** is planned (RPM version only)

⚠️ *Outpost does not ship CACKey or proprietary vendor middleware. OpenSC is the supported and tested provider.*

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

### Firefox Not Showing CAC Certificates

Manually load the OpenSC module:

Firefox → `about:preferences` → **Certificates → Security Devices → Load**
Module path:

```
/usr/lib64/opensc-pkcs11.so
```

### PC/SC Logs

```bash
journalctl -u pcscd.socket
```

### USB / Reader Hardware Logs

```bash
journalctl -k | grep -i usb
```

## Roadmap

### Chromium (RPM) CAC Support

* Add Chromium/Chrome RPM to the image (optional)
* Auto-register OpenSC PKCS#11 module for NSS-based apps

### Additional Goals

* Optional hardened/enterprise configuration profile
* TPM-backed trust store integration (future Fedora feature)

## Issues

If you encounter problems, open an issue and include relevant logs:

```bash
journalctl -u pcscd.socket
opensc-tool -l
```

This helps diagnose reader issues, USB enumeration failures, and middleware problems.